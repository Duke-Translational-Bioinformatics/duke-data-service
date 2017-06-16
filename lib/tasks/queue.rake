namespace :queue do
  namespace :errors do
    desc 'Returns the number of messages in the error queue'
    task message_count: :environment do
      count = ErrorQueueHandler.new.message_count
      puts "Error queue message count is #{count}"
    end

    desc 'Lists the id, routing_key, and payload for each message. Reduce scope with ROUTING_KEY=xxx and LIMIT=###'
    task messages: :environment do
      limit = ENV['LIMIT'].to_i if ENV['LIMIT']
      ErrorQueueHandler.new.messages(routing_key: ENV['ROUTING_KEY'], limit: limit).each do |msg|
        puts "#{msg[:id]} [#{msg[:routing_key]}] \"#{msg[:payload]}\""
      end
    end

    desc 'Requeues the message with id that matches MESSAGE_ID to the gateway exchange'
    task requeue_message: :environment do
      if id = ENV['MESSAGE_ID']
        begin
          if msg = ErrorQueueHandler.new.requeue_message(id)
            puts "#{msg[:id]} [#{msg[:routing_key]}] \"#{msg[:payload]}\""
            puts "Message requeue successful!"
          else
            puts "Message #{id} not found."
          end
        rescue => e
          $stderr.puts "An error occurred while requeueing message #{id}:"
          $stderr.puts e.to_s
        end
      else
        $stderr.puts "MESSAGE_ID required; set to hex id of message to requeue."
      end
    end

    desc 'Requeues all the messages in the error queue to the gateway exchange'
    task requeue_all: :environment do
      begin
        msgs = ErrorQueueHandler.new.requeue_all
        msgs.each do |msg|
          puts "#{msg[:id]} [#{msg[:routing_key]}] \"#{msg[:payload]}\""
        end
        puts "#{msgs.length} messages requeued."
      rescue => e
        $stderr.puts "An error occurred while requeueing messages:"
        $stderr.puts e.to_s
      end
    end

    desc 'Requeues messages in the error queue with ROUTING_KEY to the gateway exchange. Reduce scope with LIMIT=###'
    task requeue_messages: :environment do
      if routing_key = ENV['ROUTING_KEY']
        limit = ENV['LIMIT'].to_i if ENV['LIMIT']
        begin
          msgs = ErrorQueueHandler.new.requeue_messages(routing_key: routing_key, limit: limit)
          msgs.each do |msg|
            puts "#{msg[:id]} [#{msg[:routing_key]}] \"#{msg[:payload]}\""
          end
          puts "#{msgs.length} messages requeued."
        rescue => e
          $stderr.puts "An error occurred while requeueing messages:"
          $stderr.puts e.to_s
        end
      else
        $stderr.puts "ROUTING_KEY required; set to routing key of messages to requeue."
      end
    end
  end

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
