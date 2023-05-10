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
      # upsert_project!(name)
      ## Don't forget to insert the sample "Project" fluxcd

      #loop do
        # reconcile_projects

        projer.run

        # puts "ran the project reconciler, sleeping now"
        # t0 = Time.now

        # sleep 400 # Nice round number, 400s
        # puts "project reconciler running again after #{Time.now - t0} seconds"
      #end
    end
    Fiber.schedule do
      #loop do
        # reconcile_leaves

        leafer.run
        # Using fibers may impact our ability to use the debugger... let's see

        # puts "ran the leaf reconciler, sleeping now"
        # t0 = Time.now

        # sleep 21600 # 60*60*24/4
        # puts "leaf reconciler running again after #{Time.now - t0} seconds"
      #end
    end
  end
end
