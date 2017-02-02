class ApplicationJob < ActiveJob::Base
  def self.gateway_exchange
    channel.exchange(opts[:exchange], opts[:exchange_options])
  end

  def self.distributor_exchange
    channel.exchange('active_jobs', type: :direct, durable: true)
  end

  def self.message_log_queue
    channel.queue('message_log', durable: true)
  end

  private

  def self.opts
    Sneakers::CONFIG
  end

  def self.session
    @conn ||= opts[:connection] || Bunny.new(@opts[:amqp], :vhost => @opts[:vhost], :heartbeat => @opts[:heartbeat], :logger => Sneakers::logger)
    @conn.start
  end

  def self.channel
    @channel ||= conn.create_channel
  end
end
