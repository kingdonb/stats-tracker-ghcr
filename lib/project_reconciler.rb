require 'kubernetes-operator'
require 'open-uri'
require 'gammo'
require 'pry'
require 'yaml'

# basedir = File.expand_path('../app/models', __FILE__)
# Dir["#{basedir}/*.rb"].each do |path|
#   name = "#{File.basename(path, '.rb')}"
#   autoload name.classify.to_sym, "#{basedir}/#{name}"
# end

require 'active_record'
require './app/models/application_record'
# Bundler.require(*Rails.groups)
require 'pg'
require 'dotenv'

require './app/models/github_org'

module Project
  class Operator
    def initialize
      crdGroup = "example.com"
      crdVersion = "v1alpha1"
      crdPlural = "projects"

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
      @logger.info("create new project with the name #{obj["spec"]["projectName"]}")
      @eventHelper.add(obj,"an event from upsert")

      create_new_leaves(obj)

      k8s = @opi.instance_variable_get("@k8sclient")
      @ts.each do |t|
        name = t[0].gsub("/", "-")
        origName = t[0]
        # binding.pry if name == "charts-flagger"
        path = t[1]
        image = path.split("/")[6]
        # binding.pry if name == "charts-flagger"

        # d = <<~YAML
        #   ---
        #   kind: Leaf
        #   apiVersion: example.com/v1alpha1
        #   metadata:
        #     name: "#{name}"
        #   spec:
        #     projectName: "fluxcd"
        #     packageName: "#{image}"
        # YAML

        begin
          l = k8s.get_leaf(name, 'default')
          if l.respond_to?(:kind)
            next # leaf is already present on the cluster, don't re-create it
          end
        rescue Kubeclient::ResourceNotFoundError => e
          # this is the signal to proceed, create the leaf
        end

        k8s.create_leaf(Kubeclient::Resource.new({
          metadata: {
            name: name, namespace: 'default'
          },
          spec: {
            projectName: 'fluxcd', packageName: image, repoName: origName
          }
        }))

        # binding.pry if name == "charts/flagger"
      end

      gho = ::GithubOrg.find_or_create_by(name: 'fluxcd')

      {:status => {:message => "upsert works fine"}}
    end

    def delete(obj)
      @logger.info("delete project with the name #{obj["spec"]["projectName"]}")
    end

    def create_new_leaves(obj)
      # name = obj["metadata"]["name"]
      project = obj["spec"]["projectName"]

      client = Proc.new do |url|
        URI.open(url)
      end

      c = client.call("https://github.com/orgs/#{project}/packages")
      h = c.read
      l = Gammo.new(h)

      g = l.parse
      d = g.css("div#org-packages div.flex-auto a.text-bold")
      @ts = {}
      # binding.pry
      d.map{|t|
        title = t.attributes["title"]
        href = t.attributes["href"]
        @ts[title] = href
      }

      # create one Leaf for each t in ts
    end
  end
end
