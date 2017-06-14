class MessageLogQueueHandler
  attr_writer :work_duration
  DEFAULT_WORK_DURATION=300
  def work_duration
    @work_duration || DEFAULT_WORK_DURATION
  end
  def index_messages
    worker = MessageLogWorker.new
    worker.run
    sleep 1
    worker.stop
  end
end
