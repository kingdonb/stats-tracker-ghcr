require 'bundler/setup'
require 'fiber_scheduler'
require 'thor'
require './lib/project_reconciler'
require './lib/leaf_reconciler'
require './lib/sample'

basedir = File.expand_path('../app/models', __FILE__)
Dir["#{basedir}/*.rb"].each do |path|
  name = "#{File.basename(path, '.rb')}"
  autoload name.classify.to_sym, "#{basedir}/#{name}"
end

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
    Sample.ensure(leafer)
  end
end
