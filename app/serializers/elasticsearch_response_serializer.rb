class ElasticsearchResponseSerializer < ActiveModel::Serializer
  attributes :results, :aggs

  def filter(keys)
    keys.delete(:aggs) if object.aggs.nil?
    keys
  end
end
