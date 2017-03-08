web: bundle exec puma -C config/puma.rb
message_log_worker: bundle exec rake workers:message_logger:run
project_storage_init_job: bundle exec rake workers:initialize_project_storage:run
child_deletion_job: bundle exec rake workers:delete_children:run
