namespace :queue do
  namespace :message_log do
    desc 'Index messages for a duration. Set duration with MESSAGE_LOG_WORK_DURATION=###'
    task index_messages: :environment do
      handler = MessageLogQueueHandler.new
      handler.work_duration = ENV['MESSAGE_LOG_WORK_DURATION'].to_i if ENV['MESSAGE_LOG_WORK_DURATION']
      puts "Indexing messages for #{handler.work_duration} seconds"
      handler.index_messages
    end
  end
end
