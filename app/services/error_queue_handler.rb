class ErrorQueueHandler
  def message_count
    count = 0
    with_error_queue do |error_queue|
      count = error_queue.message_count
    end
    count
  end

  def messages(routing_key: nil, limit: nil)
    msgs = []
    with_error_queue do |error_queue|
      last_message = nil
      error_queue.message_count.times do |i|
        last_message = error_queue.pop(manual_ack: true)
        msgs << last_message unless routing_key && 
          last_message.first[:routing_key] != routing_key
        break if limit && msgs.length == limit
      end
      error_queue.channel.nack(last_message[0].delivery_tag, true, true) if last_message
    end
    msgs.collect do |m|
      payload = Base64.decode64(JSON.parse(m.last)['payload'])
      {
        id: Digest::SHA256.hexdigest(payload),
        payload: payload,
        routing_key: m.first[:routing_key]
      }
    end
  end

  def requeue_message(id)
  end

  def requeue_all
  end

  def requeue_messages(routing_key:, limit: nil)
  end

  private

  def with_error_queue
    bunny_session.with_channel do |channel|
      error_queue = channel.queue(Sneakers::CONFIG[:retry_error_exchange], durable: true)
      yield error_queue
    end
  end

  def bunny_session
    Sneakers::CONFIG[:connection].start
  end
end
