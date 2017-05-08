class MessageLogWorker
  include Sneakers::Worker
  from_queue 'message_log'

  def work_with_params(msg, delivery_info, metadata)
    Rails.logger.info({
      MESSAGE_LOG: {
        message: msg,
        delivery_info: delivery_info,
        metadata: metadata
      }
    }.to_json)
    ack!
  end
end
