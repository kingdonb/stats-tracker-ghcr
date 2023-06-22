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
require './app/models/package'
require './lib/ar_base_connection'

module Project
  class Operator
    require './lib/operator_utility'
    def initialize
    end

    def run
      crdVersion = "v1alpha1"
      crdPlural = "projects"
      @api = AR::BaseConnection.
        new(version: crdVersion, plural: crdPlural, poolSize: 0)

      init_k8s_only
      @opi.run
    end
    
    def upsert(obj)
      projectName = obj["spec"]["projectName"]
      @logger.info("create new project {projectName: #{projectName}}")

      create_new_leaves(obj)

      k8s = @opi.instance_variable_get("@k8sclient")

      time_t = DateTime.now.in_time_zone.to_time
      count = @ts.count

      @ts.each do |t|
        name = t[0].gsub("/", "-") # Slashes are not permitted in RFC-1123 names
        origName = t[0]

        path = t[1][0]
        image = path.split("/")[6]
        repoName = t[1][1]

        # if name == "source-controller" # DEBUGGING

        # d = <<~YAML
        #   ---
        #   kind: Leaf
        #   apiVersion: example.com/v1alpha1
        #   metadata:
        #     name: "#{name}"
        #   spec:
        #     projectName: "fluxcd"
        #     packageName: "#{image}"
        #     repoName: "#{origName}"
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
            projectName: projectName, packageName: image, repoName: repoName
          }
        }))

        # end # if-source-controller DEBUGGING
      end

      # If we could pass last_update ahead, to the health checker...
      # but now it sits in a separate process under foreman!
      last_update = DateTime.now.in_time_zone.to_time
      # Consider any changes since we started reconciling (time_t) as progress and mark us ready.
      register_health_check(k8s: k8s, count: count, last_update: time_t, project_name: projectName)
      @eventHelper.add(obj,"registered health check for leaves from project/#{projectName}")

      {:status => {
        :count => count.to_s,
        :lastUpdate => time_t,
        # :conditions => 
      }}
    end

    def delete(obj)
      project_name = obj["spec"]["projectName"]
      @logger.info("delete project with the name #{project_name}")
      gho = ::GithubOrg.find_by(name: project_name)
      pkgs = ::Package.where(repository: {github_org_id: 1}).includes(:repository)
      if pkgs.count > 0
        k8s = @opi.instance_variable_get("@k8sclient")
        @logger.info("deleting any leaves with the projectName #{project_name}")

        # delete_options = Kubeclient::Resource.new(
        #   apiVersion: 'example.com/v1alpha1',
        #   gracePeriodSeconds: 0,
        #   kind: 'DeleteOptions'
        # )
        pkgs.each do |pkg|
          begin
          name = pkg.name
          leaf_name = if "charts%2Fflagger" == name
                        "charts-flagger"
                      else
                        name
                      end
          namespace = 'default'
          k8s.delete_leaf(leaf_name, namespace, {})
          rescue Kubeclient::ResourceNotFoundError
            # it's already deleted
          end
        end
      end
      @logger.info("reached the end of delete for Project named: #{project_name}")
    end

    def register_health_check(k8s:, count:, last_update:, project_name:)
      # Store the number of packages from @ts for health checking later
      gho = ::GithubOrg.find_or_create_by(name: project_name)
      gho.updated_at = last_update
      gho.package_count = count
      gho.save!

      # Health checks are done in a concurrent (foreman) job
      # # Do the health checking (later)
      # Fiber.schedule do
      #   gho.run(k8s: k8s, last_update: last_update)
      # end
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

      d.map{|t|
        title = t.attributes["title"]
        href = t.attributes["href"]

        # Ignore these 2y+ old images with no parent repository
        unless /-arm64$/ =~ title
          s = t.next_sibling.next_sibling
          str_len = project.length

          repo = s.children[5].inner_text
          # Published on ... by Flux project in fluxcd/flagger
          if /\A#{project}\// =~ repo # remove "fluxcd/"
            repo.slice!(0, str_len + 1)
          end

          @ts[title] = [href, repo]
        end
      }

      # create one Leaf for each t in ts
    end
  end
end
