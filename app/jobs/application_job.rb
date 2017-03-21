class ApplicationJob < ActiveJob::Base
  class QueueNotFound < ::StandardError
  end
  before_enqueue do |job|
    if self.class.queue_adapter == ActiveJob::QueueAdapters::SneakersAdapter &&
        !ApplicationJob.conn.queue_exists?(queue_name)

      raise QueueNotFound.new("Queue #{queue_name} does not exist")
    end
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

      distributor.bind(gateway)
    end
  end

  def self.job_wrapper
    check_interface_error
    create_bindings
    klass = self
    Class.new(ActiveJob::QueueAdapters::SneakersAdapter::JobWrapper) do
      from_queue klass.queue_name,
        arguments: {'x-dead-letter-exchange': "#{klass.queue_name}-retry"},
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

  def self.initialize_job(transactionable)
    check_interface_error
    raise ArgumentError.new("object is not job_transactionable") unless transactionable.respond_to?('job_transactionable?')
    JobTransaction.create(transactionable: transactionable, key: self.queue_name, state: 'initialized')
  end

  def self.start_job(transaction)
    transaction.update(state: 'in progress')
  end

  def self.complete_job(transaction)
    transaction.update(state: 'complete')
  end

  def self.check_interface_error
    if self == ApplicationJob
      raise NotImplementedError, 'The job_wrapper method should only be called on subclasses of ApplicationJob'
    end
    true
  end
end
