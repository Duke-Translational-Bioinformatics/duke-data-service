require 'sneakers/handlers/maxretry'

sneakers_workers = ENV['SNEAKER_WORKERS'] || 1
sneakers_worker_delay = ENV['SNEAKER_WORKER_DELAY'] || 10
sneakers_prefetch = ENV['SNEAKERS_PREFECTH'] || 1
sneakers_threads = ENV['SNEAKERS_THREADS'] || 1

Sneakers.configure(
  :workers => sneakers_workers,
  :start_worker_delay => sneakers_worker_delay,
  :prefetch => sneakers_prefetch,
  :threads => sneakers_threads,
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
