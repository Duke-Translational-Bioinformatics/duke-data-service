class MessageLogQueueHandler
  def index_messages
    worker = MessageLogWorker.new
    each_message do |msg, channel, delivery_tags|
      worker.work_with_params(msg[2], msg[0], msg[1])
      channel.ack(delivery_tags.pop)
    end
  end

  private

  def each_message
    bunny_session.with_channel do |channel|
      message_log_queue = channel.queue(MessageLogWorker.queue_name, durable: true)
      delivery_tags = []
      begin
        message_log_queue.message_count.times do |i|
          msg = message_log_queue.pop(manual_ack: true)
          delivery_tags << msg[0].delivery_tag

          yield msg, channel, delivery_tags

        end
      ensure
        channel.nack(delivery_tags.last, true, true) if delivery_tags.any?
      end
    end
  end

  def bunny_session
    Sneakers::CONFIG[:connection].start
  end
end
