require 'kubernetes-operator'
require 'open-uri'
require 'nokogiri'
require 'yaml'
require 'semantic'

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

require './app/models/package'
require './app/models/version'
require './app/models/version_measurement'
require './lib/ar_base_connection'

module PackageVersion
  class Operator
    require './lib/operator_utility'
    def initialize
    end

    def run
      crdVersion = "v1alpha1"
      crdPlural = "packageversions"
      @api = AR::BaseConnection.
        new(version: crdVersion, plural: crdPlural, poolSize: 1)

      init_k8s_only
      @opi.run
    end
    
    def upsert(obj)
      projectName = obj["spec"]["projectName"]
      packageName = obj["spec"]["packageName"]
      @logger.info("create new packageversion {projectName: #{projectName}, packageName: #{packageName}}")

      create_new_leaves(obj)
      time_t0 = DateTime.now.in_time_zone.to_time

      k8s = @opi.instance_variable_get("@k8sclient")

      pack = nil
      loop do
        pack = Package.find_by(name: packageName)
        break if pack.present?
        sleep 2
      end

      overall_count = 0
      VersionMeasurement.transaction do |t|
        @ts.each do |t|
          v = t[0]
          count = t[1][0]

          begin
            version = Semantic::Version.new(v)
            vers = Version.find_or_create_by(package: pack, version: version.to_s)
            measure = VersionMeasurement.new(
              measured_at: time_t0,
              count: count,
              package: pack,
              version: vers
            )
            measure.save!

            overall_count = overall_count + 1

          rescue ArgumentError
            # filter as it did not parse as semver
          end
        end
      end

      @logger.info("reached the end for packageversion {projectName: #{projectName}, packageName: #{packageName}}")
      time_t1 = DateTime.now.in_time_zone.to_time

      {:status => {
        :count => overall_count.to_s,
        :lastUpdate => time_t1,
        # :conditions => 
      }}
    end

    def delete(obj)
    end

    def create_new_leaves(obj)
      # name = obj["metadata"]["name"]
      project = obj["spec"]["projectName"]
      package = obj["spec"]["packageName"]

      client = Proc.new do |url|
        URI.open(url)
      end

      url = "https://github.com/#{project}/#{package}/pkgs/container/#{package}/versions?filters%5Bversion_type%5D=tagged"
      c = client.call(url)
      html = c.read
      h = Nokogiri::HTML(html)

      d = h.css("a.Label")
      @ts = {}

      d.map{|t|
        v = t.text
        # Ignore these signatures that do not look like semver
        if v[0] == "v"
          version = v[1..]
          ppp = t.parent.parent.parent
          counter = ppp.css('div span.color-fg-muted.overflow-hidden.f6.mr-3')
          count = counter.text.strip.gsub(',','').to_i

          @ts[version] = [count]
        end
      }

      # create one Leaf for each t in ts
    end
  end
end
