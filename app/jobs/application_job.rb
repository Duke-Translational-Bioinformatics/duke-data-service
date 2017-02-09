class ApplicationJob < ActiveJob::Base
  class QueueNotFound < ::StandardError
  end
  before_enqueue do |job|
    raise QueueNotFound.new("Queue #{queue_name} does not exist") unless ApplicationJob.conn.queue_exists? queue_name
  end

  def self.distributor_exchange_name
    'active_jobs'
  end

  def self.distributor_exchange_type
    :direct
  end

  def self.create_bindings
    conn.with_channel do |channel|
      gateway = channel.exchange(opts[:exchange], opts[:exchange_options])
      distributor = channel.exchange(
        distributor_exchange_name, 
        type: distributor_exchange_type, durable: true
      )
      message_log = channel.queue('message_log', durable: true)

      distributor.bind(gateway)
      message_log.bind(gateway)
    end
  end

  def self.job_wrapper
    if self == ApplicationJob
      raise NotImplementedError, 'The job_wrapper method should only be called on subclasses of ApplicationJob'
    end

    create_bindings
    klass = self
    Class.new(ActiveJob::QueueAdapters::SneakersAdapter::JobWrapper) do
      from_queue klass.queue_name,
        exchange: klass.distributor_exchange_name,
        exchange_type: klass.distributor_exchange_type
    end
  end

  private

  def self.opts
    Sneakers::CONFIG
  end

  def self.conn
    conn = opts[:connection] || Bunny.new(opts[:amqp], :vhost => opts[:vhost], :heartbeat => opts[:heartbeat], :logger => Sneakers::logger)
    conn.start
  end
end
