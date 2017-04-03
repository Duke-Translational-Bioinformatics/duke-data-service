require 'sneakers/handlers/maxretry'

Sneakers.configure(
  :exchange => 'message_gateway',
  :log => Rails.logger,
  :handler => Sneakers::Handlers::Maxretry,
  :retry_error_exchange => 'active_jobs-error',
  :timeout_job_after => 60,
  :exchange_options => {
    :type => :fanout
  }
)
Sneakers.configure(
  connection: Bunny.new( ENV['CLOUDAMQP_URL'],
    :heartbeat => Sneakers::CONFIG[:heartbeat],
    :logger => Sneakers::logger
  )
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
