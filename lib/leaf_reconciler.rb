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
require './lib/ar_base_connection'

module Leaf
  class Operator
    def initialize()
      # init_connections
    end

    def init_k8s_only
      @opi = @api[:opi]
      @logger = @opi.getLogger
      @eventHelper = @opi.getEventHelper
      @opi.setUpsertMethod(method(:upsert))
      @opi.setDeleteMethod(method(:delete))
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

    def run
      # k8s = k8s_client

      # # it's not unheard of that some leaves are already in the cluster on startup
      # leaves = k8s.get_leaves(namespace: 'default')
      # # binding.pry
      # # it might not be too late for these leaves, try calling upsert on them again
      # leaves.each do |leaf|
      #   # binding.pry
      #   resp = upsert(leaf)
      #   # update status
      #   if resp.is_a?(Hash) && resp[:status]
      #     # binding.pry
      #     k8s.patch_entity('leaves', leaf[:metadata][:name]+"/status", {status: resp[:status]}, 'merge-patch', 'default')
      #   end
      # end
      # binding.pry

      # Fiber.schedule {
        #begin
      # We don't want forked processes to inherit this part, so
      # call kubernetes-operator run method in a forked process
      # pid = Process.fork do
        #if pid.nil?
        #  @logger.info("we are in the fork (pid:#{pid})}")
          #reinit_connections

          # register callbacks for upsert and delete
      crdVersion = "v1alpha1"
      crdPlural = "leaves"
      @api = AR::BaseConnection.
        new(version: crdVersion, plural: crdPlural, poolSize: 0)

      init_k8s_only
      # set reconcileAt on any 
      @opi.run
        # else
        #   @logger.info("this log message should never be printed}")
        # end
      # end
      # @logger.info("forked and waiting for reconciler (pid:#{pid})}")
      # Process.wait pid
      # @logger.info("leaf reconciler exited")
        #rescue => exception
        #  binding.pry
        #end
      #}
    end

    def upsert(obj)
      packageName = obj["spec"]["packageName"]
      name = obj["metadata"]["name"]
      @logger.info("upsert called for {packageName: #{packageName}}")

      project = obj["spec"]["projectName"]
      repo = obj["spec"]["repoName"]
      image = obj["spec"]["packageName"]

      k8s = k8s_client
      store = @opi.instance_variable_get("@store")

      patch = {:status => {}}

    if is_under_deletion?(obj)
      @logger.info("(is under deletion) {packageName: #{packageName}}")
      patch = handle_deletion(obj)
    else
      if is_already_ready?(obj)
        @logger.info("leaf upsert was called, but short-circuiting (it's already ready) leaf/#{name}")
        # @eventHelper.add(obj,"leaf upsert was called, but short-circuiting (it's already ready) leaf/#{name}")
      else
        if is_already_reconciling?(obj)
          @logger.info("is marked as reconciling from a previous call to upsert leaf/#{name}")

          patch = handle_reconciling(obj)

        else
          @logger.info("doing the thing (scheduling a fiber and patching NewGeneration into the status) leaf/#{name}")
          patch = reconcile(obj)
        end # block where: set initial status condition, unless already_reconciling
      end # block where: short circuit when already_ready
    end # block where: unless is_under_deletion

      # Return a condition patch, or an empty status hash for final merge
      return patch
    end

    def reconcile(obj)
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
        name = obj["metadata"]["name"]
        pid = Process.spawn "bundle exec ruby ./lib/reconcile_leaf.rb #{name}"

        Process.wait(pid)
      end
      return patch
    end

    def handle_reconciling(obj)
          rec = fetch_condition_by_type(obj: obj, cond_type: 'Reconciling')
          how_long = Time.now - Time.parse(rec.lastTransitionTime)
          stalled = how_long > 5 # seconds

          name = obj["metadata"]["name"]
          generation = obj["metadata"]["generation"]

          if stalled
            @logger.info("stalled, rescheduling leaf/#{name}")
            patch = {:status => {
              :conditions => [{
                :lastTransitionTime => DateTime.now,
                :message => "Stalled for #{how_long}s",
                :observedGeneration => generation,
                :reason => "RetryNeeded",
                :status => "True",
                :type => "Stalled"
              }, {
                :lastTransitionTime => DateTime.now,
                :message => "Stalled",
                :observedGeneration => generation,
                :reason => "Rescheduled",
                :status => "False",
                :type => "Ready"
              }
              ]
            }}
          end
    end

    def handle_deletion(obj)
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
    end

    def delete(obj)
      @logger.info("delete leaf with the name #{obj["spec"]["packageName"]}")
      k8s = k8s_client
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

    def k8s_client
      @opi.instance_variable_get("@k8sclient")
    end
  end
end
