Sneakers.configure(
  :amqp => ENV['CLOUDAMQP_URL'],
  :exchange => 'message_gateway',
  :exchange_options => {
    :type => :fanout
  }
)
Sneakers.logger = Rails.logger
