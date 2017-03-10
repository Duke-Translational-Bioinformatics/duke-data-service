class ElasticsearchIndexJob < ApplicationJob
  queue_as :elasticsearch_index

  def perform(container, update: false)
    if update
      container.__elasticsearch__.update_document
    else
      container.__elasticsearch__.index_document
    end
  end
end
