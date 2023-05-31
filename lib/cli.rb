require 'bundler/setup'
require 'fiber_scheduler'
require 'thor'
require './lib/project_reconciler'
require './lib/leaf_reconciler'

class MyCLI < Thor

  desc "controller ORG", "Create a Project for the GitHub ORG and start reconciling it"
  def controller(name: "fluxcd")
    # puts "calling Fiber.schedule for do_update loop"
    Fiber.set_scheduler(FiberScheduler.new)

    projer = Project::Operator.new
    leafer = Leaf::Operator.new

    Fiber.schedule do
        projer.run
    end
    Fiber.schedule do
        leafer.run
    end
  end
end
