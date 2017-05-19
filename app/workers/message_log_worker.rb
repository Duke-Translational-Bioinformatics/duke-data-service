class MessageLogWorker
  include Sneakers::Worker
  from_queue 'message_log'

  def work_with_params(msg, delivery_info, metadata)
    select_delivery_info = delivery_info.to_hash.select do |k,v|
      %w{consumer_tag delivery_tag redelivered exchange routing_key}.include?(k.to_s)
    end
    Elasticsearch::Model.client.index({
      index: 'queue_messages',
      type: delivery_info[:routing_key],
      body: {
        message: {
          payload: msg.to_json,
          delivery_info: select_delivery_info.to_json,
          properties: metadata.to_json
        }
      }
    })
    ack!
  end
end
