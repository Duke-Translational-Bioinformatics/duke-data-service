Elasticsearch::Model.client = Elasticsearch::Client.new(
  host: ENV['BONSAI_URL'],
  logger: Rails.logger
)
