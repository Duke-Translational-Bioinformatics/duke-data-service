workers Integer(ENV['WEB_CONCURRENCY'] || 2)
threads_count = Integer(ENV['MAX_THREADS'] || 5)
threads threads_count, threads_count

preload_app!

rackup      DefaultRackup
if ENV['LOCALDEV'] && !ENV['NOFORCESSL']
  bind "ssl://0.0.0.0:3000?key=/etc/pki/tls/private/localhost.key&cert=/etc/pki/tls/certs/localhost.crt&keystore=/var/www/app/config/keystore/keystore.jks&keystore-pass=password"
else
  port        ENV['PORT']     || 3000
  environment ENV['RACK_ENV'] || 'development'
end

on_worker_boot do
  # Worker specific setup for Rails 4.1+
  # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  ActiveRecord::Base.establish_connection
end
