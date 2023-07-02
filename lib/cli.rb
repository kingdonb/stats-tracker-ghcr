require 'bundler/setup'
require 'fiber_scheduler'
require 'thor'
require 'pry'

require './lib/project_reconciler'
require './lib/leaf_reconciler'
require './lib/sample'
require './app/models/measurement'
require './lib/package_version_reconciler'
# require './lib/version_leaf_reconciler'
require './lib/pkv_sample'
require './app/models/version_measurement'

class MyCLI < Thor

  desc "sample ORG", "Create a Project for the GitHub ORG and Reconcile projects"
  def sample(name: "fluxcd")
    projer = Project::Operator.new
    Sample.ensure()
    projer.run
  end

  desc "proj", "Reconcile the projects (GithubOrgs)"
  def proj()
    # Fiber.set_scheduler(FiberScheduler.new)
    projer = Project::Operator.new

    projer.run
  end

  desc "leaf", "Reconcile the leaves (Packages)"
  def leaf()
    Fiber.set_scheduler(FiberScheduler.new)
    leafer = Leaf::Operator.new

    leafer.run
  end

  desc "measure", "Do the measurement (Health Checks)"
  def measure()
    # Fiber.set_scheduler(FiberScheduler.new)
    Measurement.call
  end

  desc "pkvsample PKG", "Create a PackageVersion for the Kustomize Controller (or PKG) and Reconcile PackageVersions"
  def pkvsample(name: "fluxcd", pkvname: "kustomize-controller")
    packageversioner = PackageVersion::Operator.new
    PkvSample.ensure()
    packageversioner.run
  end

  desc "packageversion", "Reconcile the packageversions"
  def packageversion()
    # Fiber.set_scheduler(FiberScheduler.new)
    packageversioner = PackageVersion::Operator.new

    packageversioner.run
  end

  # desc "versionleaf", "Reconcile the versionleaves"
  # def versionleaf()
  #   Fiber.set_scheduler(FiberScheduler.new)
  #   versionleafer = VersionLeaf::Operator.new

  #   versionleafer.run
  # end

  # desc "measure", "Do the measurement (PackageVersion/Leaves)"
  # def measver()
  #   # Fiber.set_scheduler(FiberScheduler.new)
  #   VersionMeasurement.call
  # end
end
