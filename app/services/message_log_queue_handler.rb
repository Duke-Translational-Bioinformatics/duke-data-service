class MessageLogQueueHandler
  def index_messages
    worker = MessageLogWorker.new
    worker.run
    sleep 1
    worker.stop
  end
end
