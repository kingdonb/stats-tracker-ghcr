
# Require me directly inside of your Operator class

    def init_k8s_only
      @opi = @api[:opi]
      @logger = @opi.getLogger
      @eventHelper = @opi.getEventHelper
      @opi.setUpsertMethod(method(:upsert))
      @opi.setDeleteMethod(method(:delete))
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

