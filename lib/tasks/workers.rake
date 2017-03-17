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
      workers = [ ProjectStorageProviderInitializationJob.job_wrapper ]
      Sneakers::Runner.new(workers).run
    end
  end

  namespace :delete_children do
    desc 'run a ChildDeletionJob'
    task run: :environment do
      workers = [ ChildDeletionJob.job_wrapper ]
      Sneakers::Runner.new(workers).run
    end
  end

  namespace :index_documents do
    desc 'run an ElasticsearchIndexJob'
    task run: :environment do
      workers = [ ElasticsearchIndexJob.job_wrapper ]
      Sneakers::Runner.new(workers).run
    end
  end
end
