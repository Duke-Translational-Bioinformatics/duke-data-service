class ApplicationJob < ActiveJob::Base
  include JobTracking

  class QueueNotFound < ::StandardError
  end
  before_enqueue do |job|
    if ENV['SNEAKERS_SKIP_QUEUE_EXISTS_TEST'].nil? &&
        self.class.queue_adapter.is_a?(ActiveJob::QueueAdapters::SneakersAdapter) &&
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
    if self == ApplicationJob
      raise NotImplementedError, 'This method should only be called on subclasses of ApplicationJob'
    end

    create_bindings
    klass = self
    Class.new(ActiveJob::QueueAdapters::SneakersAdapter::JobWrapper) do
      from_queue klass.queue_name,
        arguments: {'x-dead-letter-exchange': "#{klass.queue_name}-retry"},
        exchange: klass.distributor_exchange_name,
        exchange_type: klass.distributor_exchange_type
    end
  end

  #JobTracking.transaction_key
  def self.transaction_key
    self.queue_name
  end

  #JobRunner workers_registry inclusion
  def self.should_be_registered_worker?
    true
  end

  private

  def self.opts
    Sneakers::CONFIG
  end

  def self.conn
    conn = opts[:connection]
    conn.start
  end
end
