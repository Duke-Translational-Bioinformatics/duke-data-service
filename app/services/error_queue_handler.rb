class ErrorQueueHandler
  def message_count
  end

  def messages(routing_key: nil, limit: nil)
  end

  def requeue_message(id)
  end

  def requeue_all
  end

  def requeue_messages(routing_key:, limit: nil)
  end
end
