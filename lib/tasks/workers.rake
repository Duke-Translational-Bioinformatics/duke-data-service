require 'sneakers/runner'
namespace :workers do
  desc 'run all ApplicationJob workers'
  task run: :environment do
    silence_warnings do
      Rails.application.eager_load! unless Rails.application.config.eager_load
    end
    workers = ApplicationJob.descendants.map &:job_wrapper
    Sneakers::Runner.new(workers).run
  end
end
