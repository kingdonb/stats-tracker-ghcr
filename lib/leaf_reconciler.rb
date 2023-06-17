require 'kubernetes-operator'
require 'pry'

require 'active_record'
require './app/models/application_record'
# Bundler.require(*Rails.groups)
require 'pg'
require 'dotenv'

require './app/models/github_org'
require './app/models/repository'
require './app/models/package'

module Leaf
  class Operator
    require './lib/my_wasmer'
    def initialize()
      crdGroup = "example.com"
      crdVersion = "v1alpha1"
      crdPlural = "leaves"
      # @shard = shard

      # Load DATABASE_PASSWORD into env
      Dotenv.load '.env.local'

      # TODO: make this parse or reuse the connection from database.yml
      ActiveRecord::Base.establish_connection(
        adapter:  'postgresql', # or 'postgresql' or 'sqlite3'
        database: 'dlcounts',
        username: 'thecount',
        password: ENV["GRAFANA_DOWNLOADS_APP_DATABASE_PASSWORD"],
        host:     ENV["GRAFANA_DOWNLOADS_APP_DATABASE_HOST"]
      )

      @opi = KubernetesOperator.new(crdGroup,crdVersion,crdPlural)
      @logger = @opi.getLogger
      @eventHelper = @opi.getEventHelper
      @opi.setUpsertMethod(method(:upsert))
      @opi.setDeleteMethod(method(:delete))
    end

    def run
      k8s = @opi.instance_variable_get("@k8sclient")

      # it's not unheard of that some leaves are already in the cluster on startup
      leaves = k8s.get_leaves(namespace: 'default')
      # it might not be too late for these leaves, try calling upsert on them again
      leaves.each do |leaf|
        upsert(leaf)
      end

      # the callback register for upsert and delete
      @opi.run
    end

    def upsert(obj)
      # ## sharding
      # #

      # shard_key = obj[:metadata][:uid].hash

      # unless (shard_key % 4) == (@shard - 1)
      #   return {:status => {}}
      # end

      # # there are 4 shards
      # # with shard keys: 1, 2, 3, 4
      # #
      # ## sharding

      packageName = obj["spec"]["packageName"]
      name = obj["metadata"]["name"]
      @logger.info("upsert called for {packageName: #{packageName}}")

      project = obj["spec"]["projectName"]
      repo = obj["spec"]["repoName"]
      image = obj["spec"]["packageName"]

      k8s = @opi.instance_variable_get("@k8sclient")
      store = @opi.instance_variable_get("@store")

      patch = {:status => {}}

    if is_under_deletion?(obj)
      generation = obj["metadata"]["generation"]
      patch = {:status => {
        :conditions => [{
          :lastTransitionTime => DateTime.now,
          :message => "",
          :observedGeneration => generation,
          :reason => "Terminating",
          :status => "False",
          :type => "Ready"
        }]
      }}
    else
      if is_already_ready?(obj)
        # @eventHelper.add(obj,"leaf upsert was called, but short-circuiting (it's already ready) leaf/#{name}")
      else
        if is_already_reconciling?(obj)
          # no need to set Reconciling condition, it's already set
        else
          generation = obj["metadata"]["generation"]

          # We'll be reconciling in a fiber, and upsert may get called again
          patch = {:status => {
            :conditions => [{
              :lastTransitionTime => DateTime.now,
              :message => "Reconciling new generation #{generation}",
              :observedGeneration => generation,
              :reason => "NewGeneration",
              :status => "True",
              :type => "Reconciling"
            }, {
              :lastTransitionTime => DateTime.now,
              :message => "Reconciling",
              :observedGeneration => generation,
              :reason => "Progressing",
              :status => "False",
              :type => "Ready"
            }
            ]
          }}

          # When the fiber gets back, it will store its results in the cache
          Fiber.schedule do
            watcher = k8s.watch_leaves(namespace: 'default', name: name)
            watcher.each do |notice|
              # don't act on ADDED or DELETED notices
              if notice.type == "MODIFIED"
                new_obj = notice.object

                # don't act unless Reconciling condition is set
                if is_finalizer_set?(new_obj) && is_already_reconciling?(new_obj)
                  uid = obj[:metadata][:uid]

                  # call reconcile_async when "Reconciling" is called for
                  patched = reconcile_async(obj: obj, name: name, project: project, repo: repo, image: image, k8s: k8s)

                  # avoid upsert getting called again, (but some calls may still make it through)
                  latest_version = patched[:metadata][:resourceVersion]
                  store.transaction do
                    if store[uid] < latest_version
                      store[uid] = latest_version
                      store.commit
                    end
                  end

                  # we are done here, the watcher can be terminated
                  watcher.finish
                end # block where: finalizer_set && already_reconciling
              end # block where: only MODIFIED
            end # block where: watcher.each leaf in default namespace
          end # Fiber.schedule
        end # block where: set initial status condition, unless already_reconciling
      end # block where: short circuit when already_ready
    end # block where: unless is_under_deletion

      # Return a condition patch, or an empty status hash for final merge
      return patch
    end

    def delete(obj)
      # ## sharding
      # #

      # shard_key = obj[:metadata][:uid].hash

      # unless (shard_key % 4) == (@shard - 1)
      #   return
      # end

      # # there are 4 shards
      # # with shard keys: 1, 2, 3, 4
      # #
      # ## sharding

      @logger.info("delete leaf with the name #{obj["spec"]["packageName"]}")
      k8s = @opi.instance_variable_get("@k8sclient")
      store = @opi.instance_variable_get("@store")
      name = obj["metadata"]["name"]
      generation = obj["metadata"]["generation"]

      patch = {:status => {
        :conditions => [{
          :lastTransitionTime => DateTime.now,
          :message => "Garbage collecting",
          :observedGeneration => generation,
          :reason => "Terminating",
          :status => "True",
          :type => "Reconciling"
        }, {
          :lastTransitionTime => DateTime.now,
          :message => "Garbage collecting",
          :observedGeneration => generation,
          :reason => "Terminating",
          :status => "False",
          :type => "Ready"
        }
        ]
      }}
      patched = k8s.patch_entity('leaves', name + "/status", patch, 'merge-patch', 'default')

      uid = obj[:metadata][:uid]
      latest_version = patched[:metadata][:resourceVersion]
      store.transaction do
        if store[uid] < latest_version
          store[uid] = latest_version
          store.commit
        end
      end
    end

    def is_finalizer_set?(obj)
      metadata = obj["metadata"]
      finalizers = metadata&.dig("finalizers")
      fin = finalizers&.select {|f| f == "leaves.v1alpha1.example.com"}
      return !fin&.first.nil?
    end

    def is_already_ready?(obj)
      ready = fetch_condition_by_type(
        obj: obj, cond_type: 'Ready')
      return is_current?(obj: obj, cond: ready)
    end

    def is_already_reconciling?(obj)
      reconciling = fetch_condition_by_type(
        obj: obj, cond_type: 'Reconciling')
      return is_current?(obj: obj, cond: reconciling)
    end

    def is_under_deletion?(obj)
      ts = fetch_deletion_timestamp(obj: obj)
      return !!ts
    end

    def fetch_deletion_timestamp(obj:)
      metadata = obj["metadata"]
      ts = metadata&.dig("deletionTimestamp")
    end

    def fetch_condition_by_type(obj:, cond_type:)
      status = obj["status"]
      conditions = status&.dig("conditions")
      con = conditions&.select {|c| c[:type] == cond_type}
      con&.first
    end

    def is_current?(obj:, cond:)
      metadata = obj["metadata"]
      generation = metadata&.dig(:generation)
      observed = cond&.dig(:observedGeneration)
      # binding.pry
      generation == observed
    end

    def reconcile_async(obj:, name:, project:, repo:, image:, k8s:)
      r = get_current_stat_with_time(project, repo, image)

      # @eventHelper.add(obj,"wasmer returned current download count in leaf/#{name}")

      fluxcd = nil

      loop do
        fluxcd = ::GithubOrg.find_by(name: project)
        break if fluxcd.present?
        # sleep 2
      end

      repo_obj = ::Repository.find_or_create_by(name: repo, github_org: fluxcd)
      package_obj = ::Package.find_or_create_by(name: image, repository: repo_obj)

      # @eventHelper.add(obj,"saving package count in leaf/#{name}")

      package_obj.download_count = r[:count]
      package_obj.save!

      # @eventHelper.add(obj,"saved package count in leaf/#{name}")

      t = DateTime.now

      repo_obj.run(k8s:, last_update: t.in_time_zone.to_time)
      package_obj.run(k8s:, last_update: t.in_time_zone.to_time)

      name = obj["metadata"]["name"]
      generation = obj["metadata"]["generation"]

      # @eventHelper.add(obj,"marking finally ready with patch_entity in leaf/#{name}")

      new_status = {:status => {
        :count => r[:count],
        :lastUpdate => r[:time].to_s,

        :conditions => [ {
          :lastTransitionTime => t,
          :message => "OK",
          :observedGeneration => generation,
          :reason => "Succeeded",
          :status => "True",
          :type => "Ready"
        } ]
      } }

      k8s.patch_entity('leaves', name + "/status", new_status, 'merge-patch', 'default')
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
