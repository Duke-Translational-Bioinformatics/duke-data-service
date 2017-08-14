module SearchableModel
  extend ActiveSupport::Concern

  included do
    include JobTransactionable
    include Elasticsearch::Model

    after_create :create_elasticsearch_index
    after_update :update_elasticsearch_index
  end

  def create_elasticsearch_index
    ElasticsearchIndexJob.perform_later(
      ElasticsearchIndexJob.initialize_job(self),
      self
    )
  end

  def update_elasticsearch_index
    ElasticsearchIndexJob.perform_later(
      ElasticsearchIndexJob.initialize_job(self),
      self,
      update: true
    )
  end

  def as_indexed_json(options={})
    ActiveModel::Serializer.serializer_for(self).new(self).as_json
  end
end
