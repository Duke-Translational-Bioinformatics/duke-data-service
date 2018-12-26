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

  namespace :initialize_upload_storage do
    desc 'run a UploadStorageProviderInitializationJob'
    task run: :environment do
      JobsRunner.new(UploadStorageProviderInitializationJob).run
    end
  end

  namespace :update_project_container_elasticsearch do
    desc 'run a ProjectContainerElasticsearchUpdateJob'
    task run: :environment do
      JobsRunner.new(ProjectContainerElasticsearchUpdateJob).run
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

  namespace :graph_persistence do
    desc 'run a GraphPersistenceJob'
    task run: :environment do
      JobsRunner.new(GraphPersistenceJob).run
    end
  end

  namespace :complete_upload do
    desc 'run an UploadCompletionJob'
    task run: :environment do
      JobsRunner.new(UploadCompletionJob).run
    end
  end

  namespace :purge_upload do
    desc 'run an UploadStorageRemovalJob'
    task run: :environment do
      JobsRunner.new(UploadStorageRemovalJob).run
    end
  end

  namespace :purge_children do
    desc 'run an ChildPurgationJob'
    task run: :environment do
      JobsRunner.new(ChildPurgationJob).run
    end
  end

  namespace :restore_children do
    desc 'run an ChildRestorationJob'
    task run: :environment do
      JobsRunner.new(ChildRestorationJob).run
    end
  end

  namespace :all do
    desc 'run all jobs'
    task run: :environment do
      skip_workers = (ENV['WORKERS_ALL_RUN_EXCEPT']||'').gsub(' ','').split(',')
      JobsRunner.all(except: skip_workers).run
    end
  end
end
