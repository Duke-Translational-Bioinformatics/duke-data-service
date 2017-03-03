class MessageLogWorker
  include Sneakers::Worker
  from_queue 'message_log'

  def work_with_params(msg, delivery_info, metadata)
  end
end
