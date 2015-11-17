# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment', __FILE__)

map '/' do
  run Rails.application
end

map '/portal' do
  use Rack::Static
  run lambda { |env|
    [
      200,
      {
        'Content-Type'  => 'text/html',
        'Cache-Control' => 'public, max-age=86400'
      },
      File.open('portal/index.html', File::RDONLY)
    ]
  }
end
