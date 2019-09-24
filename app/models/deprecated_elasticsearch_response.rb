class DeprecatedElasticsearchResponse
  @@indexed_models = [DataFile, Folder, Activity]
  include ActiveModel::Model
  include ActiveModel::Serialization
  attr_reader :results

  def self.indexed_models
    @@indexed_models
  end

  def initialize(query:, indices:, policy_scope:)
    raise ArgumentError.new("indices must have at least one entry") unless indices && !indices.empty?
    indices.map {|focus_model|
      raise NameError.new("object_kind #{focus_model} Not Indexed") unless @@indexed_models.include?(focus_model)
    }
    @results = []
    @indices = indices
    @query = query
    @policy_scope = policy_scope
    fetch_results
  end

  def fetch_results
    if @indices.length == 1
      @results = @policy_scope.call(@indices.first.__elasticsearch__.search(@query).records).all
    else
      to_find = {}
      Elasticsearch::Model.search(@query, @indices).results.each do |qr|
        to_find[qr.type] = [] unless to_find.has_key? qr.type
        to_find[qr.type] << qr.id
      end
      to_find.keys.each do |type_to_find|
        @results += @policy_scope.call(type_to_find.classify.constantize.where(id: to_find[type_to_find])).to_a
      end
    end
  end
end
