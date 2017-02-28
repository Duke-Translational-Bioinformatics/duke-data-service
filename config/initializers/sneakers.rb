require 'sneakers/handlers/maxretry'

Sneakers.configure(
  :amqp => ENV['CLOUDAMQP_URL'],
  :exchange => 'message_gateway',
  :log => Rails.logger,
  :handler => Sneakers::Handlers::Maxretry,
  :timeout_job_after => 60,
  :exchange_options => {
    :type => :fanout
  }
)

# Create a new Sneakers::Publisher for each JobWrapper
module ActiveJob
  module QueueAdapters
    class SneakersAdapter
      class JobWrapper #:nodoc:
        def self.publisher
          Sneakers::Publisher.new(queue_opts)
        end
      end
    end
  end
end
