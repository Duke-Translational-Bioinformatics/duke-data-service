if ENV['RUNS_RACK']
  Rack::Timeout.service_timeout = Integer(ENV['RACK_TIMEOUT_SERVICE_TIMEOUT']) if ENV.has_key?('RACK_TIMEOUT_SERVICE_TIMEOUT')
  Rack::Timeout.wait_timeout = Integer(ENV['RACK_TIMEOUT_WAIT_TIMEOUT']) if ENV.has_key?('RACK_TIMEOUT_WAIT_TIMEOUT')
  Rack::Timeout.wait_overtime = Integer(ENV['RACK_TIMEOUT_WAIT_OVERTIME']) if ENV.has_key?('RACK_TIMEOUT_WAIT_OVERTIME')
  Rack::Timeout.service_past_wait = (ENV['RACK_TIMEOUT_SERVICE_PAST_WAIT'] == 'true')
end
