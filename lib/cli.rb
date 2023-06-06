require 'bundler/setup'
require 'fiber_scheduler'
require 'thor'

require './lib/project_reconciler'
require './lib/leaf_reconciler'
require './lib/sample'

class MyCLI < Thor

  desc "sample ORG", "Create a Project for the GitHub ORG and Reconcile projects"
  def sample(name: "fluxcd")
    Fiber.set_scheduler(FiberScheduler.new)

    projer = Project::Operator.new

    projer.run
    Sample.ensure(projer)
  end

  desc "proj", "Reconcile the projects (GithubOrgs)"
  def proj()
    Fiber.set_scheduler(FiberScheduler.new)
    projer = Project::Operator.new

    projer.run
  end

  desc "leaf", "Reconcile the leaves (Packages)"
  def leaf()
    Fiber.set_scheduler(FiberScheduler.new)
    leafer = Leaf::Operator.new

    leafer.run
  end
end
