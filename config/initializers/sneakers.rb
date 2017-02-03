Sneakers.configure(
  :amqp => ENV['CLOUDAMQP_URL'],
  :exchange => 'message_gateway',
  :log => Rails.logger,
  :exchange_options => {
    :type => :fanout
  }
)
