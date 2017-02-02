class ApplicationJob < ActiveJob::Base
  def self.gateway_exchange
    channel.exchange(opts[:exchange], opts[:exchange_options])
  end

  private

  def self.opts
    Sneakers::CONFIG
  end

  def self.conn
    @conn ||= Bunny.new(opts[:amqp])
    @conn.start
  end

  def self.channel
    @channel ||= conn.create_channel
  end
end
