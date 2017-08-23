class MessageLogWorker
  include Sneakers::Worker
  from_queue 'message_log',
    :retry_error_exchange => 'message_log-error'

  def work_with_params(msg, delivery_info, metadata)
    begin
      index_queue_message(msg, delivery_info, metadata)
    rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
      Elasticsearch::Model.client.indices.create(
        index: index_name,
        body: {
          settings: {
            index: {
              number_of_shards: 1,
              number_of_replicas: 0
            }
          }
        })
      index_queue_message(msg, delivery_info, metadata)
    end
    ack!
  end

  private

  def index_name
    'queue_messages'
  end

  def index_queue_message(msg, delivery_info, metadata)
    select_delivery_info = delivery_info.to_hash.select do |k,v|
      %w{consumer_tag delivery_tag redelivered exchange routing_key}.include?(k.to_s)
    end
    Elasticsearch::Model.client.index({
      index: index_name,
      type: delivery_info[:routing_key],
      body: {
        message: {
          payload: msg.to_json,
          delivery_info: select_delivery_info.to_json,
          properties: metadata.to_json
        }
      }
    })
  end
end
