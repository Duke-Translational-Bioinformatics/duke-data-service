class ErrorQueueHandler
  def message_count
    raise "ErrorQueueHandler is deprecated due to incompatibilities with the ExponentialBackoffHandler."
    count = 0
    with_error_queue do |error_queue|
      count = error_queue.message_count
    end
    count
  end

  def messages(routing_key: nil, limit: nil)
    raise "ErrorQueueHandler is deprecated due to incompatibilities with the ExponentialBackoffHandler."
    msgs = []
    each_error_queue_message do |msg|
      msgs << serialize_message(msg) unless routing_key &&
        msg.first[:routing_key] != routing_key
      break if limit && msgs.length == limit
    end
    msgs
  end

  def requeue_message(id)
    raise "ErrorQueueHandler is deprecated due to incompatibilities with the ExponentialBackoffHandler."
    message = nil
    msgs = []
    each_error_queue_message do |msg, channel, delivery_tags|
      msgs << serialize_message(msg)
      if msgs.last[:id] == id
        republish_message(channel, msgs.last)
        channel.ack(delivery_tags.pop)
        message = msgs.last
        break
      end
    end
    message
  end

  def requeue_all
    raise "ErrorQueueHandler is deprecated due to incompatibilities with the ExponentialBackoffHandler."
    msgs = []
    each_error_queue_message do |msg, channel, delivery_tags|
      msgs << serialize_message(msg)
      republish_message(channel, msgs.last)
      channel.ack(delivery_tags.pop)
    end
    msgs
  end

  def requeue_messages(routing_key:, limit: nil)
    raise "ErrorQueueHandler is deprecated due to incompatibilities with the ExponentialBackoffHandler."
    msgs = []
    each_error_queue_message do |msg, channel, delivery_tags|
      if msg.first[:routing_key] == routing_key
        msgs << serialize_message(msg)
        republish_message(channel, msgs.last)
        channel.ack(delivery_tags.pop)
      end
      break if limit && msgs.length == limit
    end
    msgs
  end

  private

  def each_error_queue_message
    with_error_queue do |error_queue|
      channel = error_queue.channel
      delivery_tags = []
      begin
        error_queue.message_count.times do |i|
          msg = error_queue.pop(manual_ack: true)
          delivery_tags << msg[0].delivery_tag

          yield msg, channel, delivery_tags

        end
      ensure
        channel.nack(delivery_tags.last, true, true) if delivery_tags.any?
      end
    end
  end

  def serialize_message(msg)
    payload = Base64.decode64(JSON.parse(msg.last)['payload'])
    {
      id: Digest::SHA256.hexdigest(payload),
      payload: payload,
      routing_key: msg.first[:routing_key]
    }
  end

  def gateway_exchange(channel)
    channel.exchange(Sneakers::CONFIG[:exchange], Sneakers::CONFIG[:exchange_options])
  end

  def republish_message(channel, msg)
    gateway_exchange(channel).publish(
      msg[:payload],
      {routing_key: msg[:routing_key]}
    )
  end

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
