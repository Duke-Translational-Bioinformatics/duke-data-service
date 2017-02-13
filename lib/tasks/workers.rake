require 'sneakers/runner'
namespace :workers do
  desc 'run all ApplicationJob workers'
  task run: :environment do
    workers = ApplicationJob.descendants.map &:job_wrapper
    Sneakers::Runner.new(workers).run
  end
end
