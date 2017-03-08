require 'sneakers/runner'
namespace :workers do
  namespace :message_logger do
    desc 'run a MessageLogWorker'
    task run: :environment do
      Sneakers::Runner.new([MessageLogWorker]).run
    end
  end

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

  namespace :delete_children do
    desc 'run a ChildDeletionJob'
    task run: :environment do
      silence_warnings do
        Rails.application.eager_load! unless Rails.application.config.eager_load
      end
      workers = [ ChildDeletionJob.job_wrapper ]
      Sneakers::Runner.new(workers).run
    end
  end
end
