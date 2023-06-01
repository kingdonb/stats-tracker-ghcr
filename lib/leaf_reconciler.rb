require 'kubernetes-operator'
require 'pry'

require 'active_record'
require './app/models/application_record'
# Bundler.require(*Rails.groups)
require 'pg'
# require 'dotenv'

require './app/models/github_org'
require './app/models/repository'
require './app/models/package'

module Leaf
  class Operator
    require './lib/my_wasmer'
    def initialize
      crdGroup = "example.com"
      crdVersion = "v1alpha1"
      crdPlural = "leaves"

      @opi = KubernetesOperator.new(crdGroup,crdVersion,crdPlural)
      @logger = @opi.getLogger
      @eventHelper = @opi.getEventHelper
      @opi.setUpsertMethod(method(:upsert))
      @opi.setDeleteMethod(method(:delete))
    end

    def run 
      @opi.run
    end

    def upsert(obj)
      packageName = obj["spec"]["packageName"]
      name = obj["metadata"]["name"]
      @logger.info("create new leaf {packageName: #{packageName}}")

      project = obj["spec"]["projectName"]
      repo = obj["spec"]["repoName"]
      image = obj["spec"]["packageName"]

      k8s = @opi.instance_variable_get("@k8sclient")

      r = get_current_stat_with_time(project, repo, image)

      @eventHelper.add(obj,"wasmer returned current download count in leaf/#{name}")

      fluxcd = nil

      loop do
        fluxcd = ::GithubOrg.find_by(name: project)
        break if fluxcd.present?
        sleep 2
      end

      repo_obj = ::Repository.find_or_create_by(name: repo, github_org: fluxcd)
      package_obj = ::Package.find_or_create_by(name: image, repository: repo_obj)

      package_obj.download_count = r[:count]
      package_obj.save!

      t = DateTime.now.in_time_zone

      Fiber.schedule do
        repo_obj.run(k8s:, last_update: t)
        package_obj.run(k8s:, last_update: t)
      end
    # rescue ArgumentError => e

      # Here is where we should call our wasm module, and the fetcher
      {:status => {
        :count => r[:count],
        :lastUpdate => r[:time].to_s,
        # :conditions => 
      }}
    end

    def delete(obj)
      @logger.info("delete leaf with the name #{obj["spec"]["packageName"]}")
    end

    def get_current_stat_with_time(project, repo, image)
      client = Proc.new do |url|
        URI.open(url)
      end

      t = Time.now
      h = http_client_wrapped(client, project, repo, image)
      c = wasmer_current_download_count(h, repo, image)

      {time: t, count: c}
    end

    def http_client_wrapped(http_client, project, repo, image)

      url = "https://github.com/#{project}/#{repo}/pkgs/container/#{image}"
      http_client.call(url)

    # rescue OpenURI::HTTPError => e

    end

    def http_client_read
      http_client_wrapped.read
    end
  end
end
