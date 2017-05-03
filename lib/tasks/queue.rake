namespace :queue do
  namespace :errors do
    desc 'run a MessageLogWorker'
    task message_count: :environment do
      count = ErrorQueueHandler.new.message_count
      puts "Error queue message count is #{count}"
    end

    desc 'run a MessageLogWorker'
    task messages: :environment do
      ErrorQueueHandler.new.messages.each do |msg|
        puts "#{msg[:id]} [#{msg[:routing_key]}] \"#{msg[:payload]}\""
      end
    end
  end
end
