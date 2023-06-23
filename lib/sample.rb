require 'yaml'
require 'ap'
require './lib/ar_base_connection'

class Sample
  def self.ensure()
    crdVersion = "v1alpha1"
    crdPlural = "projects"
    api = AR::BaseConnection.
      new(version: crdVersion, plural: crdPlural, poolSize: 1)
    operator = api[:opi]
    k8s = operator.
      instance_variable_get("@k8sclient")
    docs = YAML.load_file('./deploy/bases/test/sample.yml')

    if docs.class == Hash
      docs = [docs]
    end

    docs.each do |project|
      if project["kind"] == "Project"
        name = project["metadata"]["name"]
        projectName = project["spec"]["projectName"]
        begin
          p = k8s.get_project(name, 'default')
          if p.respond_to?(:kind)
            next # project is already present on the cluster,
          end
        rescue Kubeclient::ResourceNotFoundError => e
          # this is the signal to proceed, create the project
        end

        k8s.create_project(Kubeclient::Resource.new({
          metadata: {
            name: name, namespace: 'default'
          },
          spec: {
            projectName: projectName
          }
        }))
      else
        raise StandardError, "Sample yaml was not a Project as expected"
      end
    end
  end
end
