require 'yaml'
require 'ap'
require './lib/ar_base_connection'

class PkvSample
  def self.ensure()
    crdVersion = "v1alpha1"
    crdPlural = "packageversions"
    api = AR::BaseConnection.
      new(version: crdVersion, plural: crdPlural, poolSize: 1)
    operator = api[:opi]
    k8s = operator.
      instance_variable_get("@k8sclient")
    docs = YAML.load_stream(File.read('./deploy/bases/test/pkvsample.yml'))

    if docs.class == Hash
      docs = [docs]
    end

    count = 0
    docs.each do |pkv|
      if pkv["kind"] == "PackageVersion"
        count = count + 1
        name = pkv["metadata"]["name"]
        projectName = pkv["spec"]["projectName"]
        packageName = pkv["spec"]["packageName"]
        begin
          p = k8s.get_package_version(name, 'default')
          if p.respond_to?(:kind)
            next # pkv is already present on the cluster,
          end
        rescue Kubeclient::ResourceNotFoundError => e
          # this is the signal to proceed, create the project
        end

        k8s.create_package_version(Kubeclient::Resource.new({
          metadata: {
            name: name, namespace: 'default'
          },
          spec: {
            projectName: projectName,
            packageName: packageName
          }
        }))
      else
        if count == 0
          raise StandardError, "Sample yaml was not a PackageVersion as expected"
        else
          # (do nothing, samples were created)
        end
      end
    end
  end
end
