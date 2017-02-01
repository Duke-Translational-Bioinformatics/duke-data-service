Sneakers.configure(
  :amqp => ENV['CLOUDAMQP_URL'],
  :exchange => 'message_gateway',
  :exchange_type => :fanout,
  :durable => true
)
Sneakers.logger = Rails.logger
