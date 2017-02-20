require 'sneakers/runner'
namespace :workers do
  namespace :initialize_project_storage do
    desc 'run a ProjectStorageProviderInitializationJob'
    task run: :environment do
      silence_warnings do
        Rails.application.eager_load! unless Rails.application.config.eager_load
      end
      workers = [ ProjectStorageProviderInitializationJob.job_wrapper ]
      Sneakers::Runner.new(workers).run
    end
  end
end
