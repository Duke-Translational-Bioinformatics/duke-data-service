class ProjectContainerElasticsearchUpdateJob < ApplicationJob
  queue_as :project_container_elasticsearch_update

  def perform(job_transaction, parent, page)
    self.class.start_job(job_transaction)
    parent.update_container_elasticsearch_index_project(page)
    self.class.complete_job(job_transaction)
  end
end
