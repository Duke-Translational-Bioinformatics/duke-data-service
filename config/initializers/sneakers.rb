require 'sneakers/handlers/maxretry'

sneakers_workers = ENV['SNEAKER_WORKERS'] || 1
sneakers_worker_delay = ENV['SNEAKER_WORKER_DELAY'] || 10
sneakers_prefetch = ENV['SNEAKERS_PREFECTH'] || 1
sneakers_threads = ENV['SNEAKERS_THREADS'] || 1
sneakers_runner_heartbeat = ENV['SNEAKERS_RUNNER_HEARTBEAT'] || 30
sneakers_workers_heartbeat = ENV['SNEAKERS_WORKERS_HEARTBEAT'] || 30
sneakers_share_threads = ENV['SNEAKERS_SHARE_THREADS'] ? true : false
sneakers_daemonize = ENV['SNEAKERS_DAEMONIZE'] ? true : false
sneakers_timeout_job_after = ENV['SNEAKERS_TIMEOUT_JOB_AFTER'] || 60
sneakers_connection_threaded = ENV['SNEAKERS_SINGLE_THREADED_CONNECTION'] ? false : true
sneakers_connection_continuation_timeout = ENV['SNEAKERS_CONNECTION_CONTINUATION'] || 4000

ApplicationJob.deserialization_error_retry_interval = ENV['APPLICATION_JOB_DESERIALIZATION_ERROR_RETRY_INTERVAL'] if ENV['APPLICATION_JOB_DESERIALIZATION_ERROR_RETRY_INTERVAL']

Sneakers.configure(
  :exchange => 'message_gateway',
  :exchange_options => {
    :type => :fanout
  },
  :handler => SneakersHandlers::ExponentialBackoffHandler,
  :max_retries => 6,

  # runner
  #:runner_config_file => nil,
  #:metrics => nil,
  :daemonize => sneakers_daemonize,
  :start_worker_delay => Integer(sneakers_worker_delay),
  :workers => Integer(sneakers_workers),
  :log => Rails.logger,
  #:pid_path => 'sneakers.pid',
  :amqp_heartbeat => Integer(sneakers_runner_heartbeat),

  # workers
  :timeout_job_after => Integer(sneakers_timeout_job_after),
  :prefetch => Integer(sneakers_prefetch),
  :threads => Integer(sneakers_threads),
  :share_threads => sneakers_share_threads,
  :ack => true,
  :heartbeat => Integer(sneakers_workers_heartbeat),
  :hooks => {}
)
Sneakers.configure(
  connection: Bunny.new( ENV['CLOUDAMQP_URL'],
    :heartbeat => Integer(sneakers_workers_heartbeat),
    :logger => Sneakers::logger,
    #:log_level => Logger::WARN,
    #:log_file => STDOUT,
    :automatically_recover => true, # false, will disable automatic network failure recovery
    :network_recovery_interval => '', # interval between reconnection attempts
    :threaded => sneakers_connection_threaded, # switches to single-threaded connections when set to false. Only recommended for apps that only publish messages.
    :continuation_timeout => Integer(sneakers_connection_continuation_timeout) # timeout for client operations that expect a response (e.g. Bunny::Queue#get), in milliseconds. Default is 4000 ms.
  )
)

# Create a new Sneakers::Publisher for each JobWrapper
module ActiveJob
  module QueueAdapters
    class SneakersAdapter
      class JobWrapper #:nodoc:
        def self.publisher
          @publisher ||= {}
          @publisher[queue_name] ||= Sneakers::Publisher.new(queue_opts)
        end
      end
    end
  end
end
