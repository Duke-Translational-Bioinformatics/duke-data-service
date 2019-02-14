web: bundle exec puma -C config/puma.rb
all_workers: bundle exec rake workers:all:run
message_log_worker: bundle exec rake workers:message_logger:run
project_storage_init_job: bundle exec rake workers:initialize_project_storage:run
upload_storage_init_job: bundle exec rake workers:initialize_upload_storage:run
child_deletion_job: bundle exec rake workers:delete_children:run
child_purgation_job: bundle exec rake workers:purge_children:run
child_restoration_job: bundle exec rake workers:restore_children:run
upload_storage_removal_job: bundle exec rake workers:purge_upload:run
elasticsearch_index_job: bundle exec rake workers:index_documents:run
project_container_elasticsearch_update_job: bundle exec rake workers:update_project_container_elasticsearch:run
graph_persistence_job: bundle exec rake workers:graph_persistence:run
upload_completion_job: bundle exec rake workers:complete_upload:run
