class ElasticsearchIndexJob < ApplicationJob
  queue_as :elasticsearch_index

  def perform(job_transaction, container, update: false)
    self.class.start_job job_transaction
    if update
      container.__elasticsearch__.update_document(ignore: 404) ||
        container.__elasticsearch__.index_document
    else
      container.__elasticsearch__.index_document
    end
    self.class.complete_job job_transaction
  end
end
