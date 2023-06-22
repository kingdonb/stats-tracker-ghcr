require 'kubernetes-operator'
require 'pry'
require 'open-uri'

require 'active_record'
require './app/models/application_record'
# Bundler.require(*Rails.groups)
require 'pg'
require 'dotenv'

require './app/models/github_org'
require './app/models/repository'
require './app/models/package'
require './lib/ar_base_connection'

module Leaf
  class Reconciler
    require './lib/my_wasmer'
    def initialize()
      # init_connections
    end

    def init_k8s_only
      @opi = @api[:opi]
      @logger = @opi.getLogger
      @eventHelper = @opi.getEventHelper
    end

    # (this is a do-nothing method, don't call it)
    # In the parent process, we don't use any database connections
    def init_connections
      # crdVersion = "v1alpha1"
      # crdPlural = "leaves"

      # @api = AR::BaseConnection.
      #   new(version: crdVersion, plural: crdPlural, poolSize: 0)

      # init_k8s_only
    end

    # In the forked process under each fiber, use the database
    def reinit_connections
      crdVersion = "v1alpha1"
      crdPlural = "leaves"

      @api = AR::BaseConnection.
        new(version: crdVersion, plural: crdPlural, poolSize: 1)

      init_k8s_only
    end

    def reconcile(name)
      # name = obj["metadata"]["name"]
      reinit_connections
      @logger.info("the fiber is running leaf/#{name}")

      k8s = k8s_client
      obj = k8s.get_leaf(name, 'default', {})

      generation = obj["metadata"]["generation"]
      project = obj["spec"]["projectName"]
      repo = obj["spec"]["repoName"]
      image = obj["spec"]["packageName"]

      # binding.pry
      #     # We'll be reconciling in a fiber, and upsert may get called again
      #     patch = {:status => {
      #       :conditions => [{
      #         :lastTransitionTime => DateTime.now,
      #         :message => "Reconciling new generation #{generation}",
      #         :observedGeneration => generation,
      #         :reason => "NewGeneration",
      #         :status => "True",
      #         :type => "Reconciling"
      #       }, {
      #         :lastTransitionTime => DateTime.now,
      #         :message => "Reconciling",
      #         :observedGeneration => generation,
      #         :reason => "Progressing",
      #         :status => "False",
      #         :type => "Ready"
      #       }
      #       ]
      #     }}

      #       k8s = k8s_client
      #       watcher = k8s.watch_leaves(namespace: 'default', name: name)
      #       watcher.each do |notice|
      #         # don't act on ADDED or DELETED notices
      #         if notice.type == "MODIFIED"
      #           @logger.info("received MODIFIED notice leaf/#{name}")
      #           new_obj = notice.object

      #           # don't act unless Reconciling condition is set
      #           if is_finalizer_set?(new_obj) && is_already_reconciling?(new_obj)
      #             @logger.info("it's time to call reconcile_async leaf/#{name}")
      #             uid = obj[:metadata][:uid]

      #             # call reconcile_async when "Reconciling" is called for
                  patched = reconcile_async(obj: obj, name: name, project: project, repo: repo, image: image, k8s: k8s)

      #             # avoid upsert getting called again, (but some calls may still make it through)
      #             latest_version = patched[:metadata][:resourceVersion]
      #             store.transaction do
      #               if store[uid] < latest_version
      #                 store[uid] = latest_version
      #                 store.commit
      #               end
      #             end

      #             @logger.info("ending watch of leaf/#{name}")
      #             # we are done here, the watcher can be terminated
      #             watcher.finish
      #           end # block where: finalizer_set && already_reconciling
      #         end # block where: only MODIFIED
      #       end # block where: watcher.each leaf in default namespace

      #       # FIXME
      #       #return patch
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
      return is_current?(obj: obj, cond: ready) &&
        is_true?(obj: obj, cond: ready) &&
        is_fresh?(obj: obj, cond: ready, stale: 10)
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

    # def last_transition_before_duration?(cond:, duration:)
    #   last_transition = cond.dig(:lastTransitionTime)
    # end

    def is_true?(obj:, cond:)
      status = cond&.dig(:status)
      status == "True"
    end

    def is_fresh?(obj:, cond:, stale:)
      time = cond&.dig(:lastTransitionTime)
      how_long = Time.now - Time.parse(time)
      too_long = how_long > stale

      !too_long
    end

    def is_current?(obj:, cond:)
      metadata = obj["metadata"]
      generation = metadata&.dig(:generation)
      observed = cond&.dig(:observedGeneration)
      generation == observed
    end

    def reconcile_async(obj:, name:, project:, repo:, image:, k8s:)
      @logger.info("in reconcile_async leaf/#{name}")
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

      @logger.info("reconcile_async ran database activities leaf/#{name}")

      name = obj["metadata"]["name"]
      generation = obj["metadata"]["generation"]

      # @eventHelper.add(obj,"marking finally ready with patch_entity in leaf/#{name}")

      new_status = {:status => {
        :count => r[:count],
        :lastUpdate => r[:time].to_s,
        # :lastHandledReconcileAt => r[:time].to_s,
        :observedGeneration => generation,
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

    def k8s_client
      @opi.instance_variable_get("@k8sclient")
    end
  end
end

reconcile_this = ARGV[0]
r = Leaf::Reconciler.new
r.reinit_connections
r.reconcile reconcile_this
