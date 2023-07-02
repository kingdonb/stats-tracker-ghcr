require 'active_record'
require './app/models/application_record'
require './app/models/package'
require './app/models/github_org'
require 'pry'

require 'pg'
require 'dotenv'

class Measurement < ApplicationRecord
  belongs_to :package

  def self.call
    database_init
    k8s = kube_init

    project = 'fluxcd'
    gho = nil
    loop do
      gho = ::GithubOrg.find_by(name: project)
      break if gho.present? && gho.package_count.present?
      # sleep 2
    end

    t = DateTime.now.in_time_zone.to_time - 5
    n = 0
    c = 0

    loop do
      # puts "###########Doing health check############"
      packs = Package.where('updated_at > ?', t)

      c = how_many_are_ready(packs, k8s: k8s)

      # This is not how you do scheduling but yolo swag
      break if c == gho.package_count || n >= 15
      puts "########### fresh packages count: #{c} (expecting #{gho.package_count}) #######"
      sleep 4
      n += 1
    end
    puts "########### final packages count: #{c} (expecting #{gho.package_count}) #######"

    if c == gho.package_count
      puts "########### cleaning up (OK!) #######"
      Measurement.do_measurement

      # Delete Sample project when we finished
      k8s.delete_project('fluxcd', 'default', {})
      gho.touch
      gho.save!
    else
      puts "########### c (#{c}) != package_count (#{gho.package_count}) #######"
      # FIXME: Leave a mess (someone should debug this mess)
    end

    waits = 10
    pkv = k8s.get_package_versions(namespace: 'default')
    pkv.each do |p|
      k8s.delete_package_version(p["metadata"]["name"], 'default')
    end

    while (g = k8s.get_leaves(namespace: 'default').count) > 0
      puts "########### g (#{g}) leaves left; still collecting #######"
      sleep 3
      waits = waits - 1
      if waits < 1
        puts "########### issing another delete, to die gracefully #######"
        k8s.delete_project('fluxcd', 'default', {})
        break
      end
    end
    waits = 5
    while (g = k8s.get_leaves(namespace: 'default').count) > 0
      puts "########### g (#{g}) leaves left; still collecting #######"
      sleep 3
      waits = waits - 1
      if waits < 1
        puts "########### (giving up) #######"
        break
      end
    end

    # events are left behind if we exit here immediately
    # sleep 5

    puts "########### this is the end of the GithubOrg#run Health Check method #######"
  end

  def self.database_init
    AR::BaseConnection.new(poolSize: 1)
  end

  def self.kube_init
    k8sclient =
    if File.exist?("#{Dir.home}/.kube/config")
      config = Kubeclient::Config.read(ENV['KUBECONFIG'] || "#{ENV['HOME']}/.kube/config")
      context = config.context
      Kubeclient::Client.new(
        context.api_endpoint+"/apis/example.com",
        "v1alpha1",
        ssl_options: context.ssl_options,
        auth_options: context.auth_options
      )
    else
      auth_options = {
        bearer_token_file: '/var/run/secrets/kubernetes.io/serviceaccount/token'
      }
      ssl_options = {}
      if File.exist?("/var/run/secrets/kubernetes.io/serviceaccount/ca.crt")
        ssl_options[:ca_file] = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
      end
      Kubeclient::Client.new(
        'https://kubernetes.default.svc'+"/apis/example.com",
        "v1alpha1",
        auth_options: auth_options,
        ssl_options:  ssl_options
      )
    end
  end

  def self.how_many_are_ready(packages, k8s:)
    # Look up each package in Kubernetes, and do the health check for each leaf
    # FiberScheduler do
    ls = k8s.get_leaves(namespace: 'default')
    return 0 if ls.count < 1

    ls.map do |l|
      is_leaf_ready?(l) ? 1 : 0
    end.reduce(:+)
  end

  def self.is_leaf_ready?(leaf)
    lastUpdate = leaf&.status&.lastUpdate
    if lastUpdate.nil?
      false
    else
      last = DateTime.parse(lastUpdate).to_time
      now = DateTime.now.in_time_zone.to_time
      ready = now - last < 120
    end
  rescue Date::Error
    return false
  # rescue Kubeclient::ResourceNotFoundError
  #   return false
  end

  def self.do_measurement
    t = DateTime.now.in_time_zone - 124
    ps = Package.where('updated_at > ?', t)
    Package.transaction do
      ps.map do |p|
        m = Measurement.new(
          measured_at: p.updated_at,
          count: p.download_count,
          package: p)
        m.save
      end
      puts "######## RECORDING MEASUREMENT NOW ##########"
    end
  end
end
