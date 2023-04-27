require 'kubernetes-operator'

module Leaf
  class Operator
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
      @logger.info("create new leaf with the name #{obj["spec"]["packageName"]}")
      @eventHelper.add(obj,"an event from upsert")
      {:status => {:message => "upsert works fine"}}
    end

    def delete(obj)
      @logger.info("delete leaf with the name #{obj["spec"]["packageName"]}")
    end
  end
end
