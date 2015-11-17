# This file is used by Rack-based servers to start the application.

map '/portal' do
  use Rack::Static,
    :urls => [
              "/css",
              "/images",
              "/js",
              "/lib"
            ],
    :root => "portal"

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

require ::File.expand_path('../config/environment', __FILE__)
run Rails.application
