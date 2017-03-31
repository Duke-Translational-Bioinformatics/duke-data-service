require 'sneakers/runner'
namespace :workers do
  namespace :message_logger do
    desc 'run a MessageLogWorker'
    task run: :environment do
      JobsRunner.new(MessageLogWorker).run
    end
  end

  namespace :initialize_project_storage do
    desc 'run a ProjectStorageProviderInitializationJob'
    task run: :environment do
      JobsRunner.new(ProjectStorageProviderInitializationJob).run
    end
  end

  namespace :delete_children do
    desc 'run a ChildDeletionJob'
    task run: :environment do
      JobsRunner.new(ChildDeletionJob).run
    end
  end

  namespace :index_documents do
    desc 'run an ElasticsearchIndexJob'
    task run: :environment do
      JobsRunner.new(ElasticsearchIndexJob).run
    end
  end

  namespace :all do
    desc 'run all jobs'
    task run: :environment do
      JobsRunner.all.run
    end
  end
end
