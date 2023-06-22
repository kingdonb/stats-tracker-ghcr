# frozen_string_literal: true

require 'forwardable'

require 'active_record'
require './app/models/application_record'
require 'dotenv'
require 'erb'
require './config/application'

module AR
  class BaseConnection
    extend Forwardable
    def_delegators :@properties, :[], :[]=
    def initialize(version:, plural:, poolSize: nil)
      @group = "example.com"
      @properties = {}
      @version = version
      @plural = plural

      # Env configuration for config/database.yml comes from .env*
      Dotenv.load '.env.local'

      # Setup ActiveRecord connection configuration
      ActiveRecord::Base.configurations =
        YAML.load(
          ERB.new(File.read(
            File.dirname(__FILE__) + '/../config/database.yml')).result,
          aliases: true
        )

      # The owner might want to override the connection pool size
      config = database_config
      if poolSize.present?
        config[:pool] = poolSize
      end

      # We're calling BaseConnection.new, likely because we have forked
      ActiveRecord::Base.establish_connection(config)

      # The KubernetesOperator will build a K8s API (HTTP client) handle
      @properties[:opi] = KubernetesOperator.new(@group,@version,@plural)
    end

    def rails_env
      Rails.env
    end

    def database_config
      ActiveRecord::Base.configurations.configurations.select do |con|
        con.env_name == rails_env
      end.first.configuration_hash.to_h.deep_dup
    end
  end
end
