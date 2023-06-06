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

    gho = GithubOrg.find_by(name: 'fluxcd')

    t = DateTime.now.in_time_zone - 5
    n = 0
    c = 0

    loop do
      # puts "###########Doing health check############"
      packs = Package.where('updated_at > ?', t)

      c = how_many_are_ready(packs, k8s: k8s)

      # Assume we get here within 5s (no, it's not really safe)
      break if c == gho.package_count || n >= 300
      puts "########### fresh packages count: #{c} (expecting #{gho.package_count}) #######"
      sleep 10
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
    end

    puts "########### this is the end of the GithubOrg#run Health Check method #######"
  end

  def self.database_init
    # Load DATABASE_PASSWORD into env
    Dotenv.load '.env.local'

    # TODO: make this parse or reuse the connection from database.yml
    ActiveRecord::Base.establish_connection(
      adapter:  'postgresql', # or 'postgresql' or 'sqlite3'
      database: 'dlcounts',
      username: 'thecount',
      password: ENV["GRAFANA_DOWNLOADS_APP_DATABASE_PASSWORD"],
      host:     'dl-count-db.turkey.local'
    )
  end

  def self.kube_init
    k8sclient = if File.exist?("#{Dir.home}/.kube/config")
      config = Kubeclient::Config.read(ENV['KUBECONFIG'] || "#{ENV['HOME']}/.kube/config")
      context = config.context
      Kubeclient::Client.new(
        context.api_endpoint+"/apis/example.com",
        "v1alpha1",
        ssl_options: context.ssl_options,
        auth_options: context.auth_options
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
      ready = now - last < 30
    end
  # rescue Kubeclient::ResourceNotFoundError
  #   return false
  end

  def self.is_package_ready?(package, k8s:)
    lastUpdate = l&.status&.lastUpdate
    if lastUpdate.nil?
      false
    else
      lastUpdate = l.status.lastUpdate
      last = DateTime.parse(lastUpdate).to_time
      now = DateTime.now.in_time_zone.to_time
      ready = now - last < 30
    end
  rescue Kubeclient::ResourceNotFoundError
    return false
  end

  def self.do_measurement
    t = DateTime.now.in_time_zone - 30
    p = Package.where('updated_at > ?', t)
    #binding.pry
    puts "######## DOING MEASUREMENT NOW ##########"
  end
end
