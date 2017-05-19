class MessageLogWorker
  include Sneakers::Worker
  from_queue 'message_log'

  def work_with_params(msg, delivery_info, metadata)
    Elasticsearch::Model.client.index({
      index: 'queue_messages',
      type: delivery_info[:routing_key],
      body: {
        message: 'blah blah blah'
      }
    })
    ack!
  end
end
