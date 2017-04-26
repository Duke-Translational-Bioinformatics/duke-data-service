class ErrorQueueHandler
  def message_count
    count = 0
    bunny_session.with_channel do |channel|
      error_queue = channel.queue(Sneakers::CONFIG[:retry_error_exchange], durable: true)
      count = error_queue.message_count
    end
    count
  end

  def messages(routing_key: nil, limit: nil)
  end

  def requeue_message(id)
  end

  def requeue_all
  end

  def requeue_messages(routing_key:, limit: nil)
  end

  private

  def bunny_session
    Sneakers::CONFIG[:connection].start
  end
end
