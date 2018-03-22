Elasticsearch::Model.client = Elasticsearch::Client.new(
  host: ENV['BONSAI_URL'],
  logger: Rails.logger,
  adapter: ::Faraday.default_adapter
)

Rails.application.config.elasticsearch_index_settings = {}
Rails.application.config.elasticsearch_index_settings[:number_of_shards] = ENV['SEARCHABLE_MODEL_SHARDS'] if ENV['SEARCHABLE_MODEL_SHARDS']
Rails.application.config.elasticsearch_index_settings[:number_of_replicas] = ENV['SEARCHABLE_MODEL_REPLICAS'] if ENV['SEARCHABLE_MODEL_REPLICAS']
