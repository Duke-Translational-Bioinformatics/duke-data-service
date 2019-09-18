require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)
require 'neo4j/railtie'

module DukeDataService
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    config.active_record.belongs_to_required_by_default = false

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.paths.add File.join('app', 'api'), glob: File.join('**', '*.rb')
    config.autoload_paths += Dir[Rails.root.join('app', 'api', '*')]

    config.eager_load_paths += %W( #{Rails.root}.join('app','jobs') )

    config.force_ssl = false
    cors_origins = '*'
    cors_origins = ENV['CORS_ORIGINS'].split(',') if ENV['CORS_ORIGINS']

    pagination_headers = [
      'X-Total',
      'X-Total-Pages',
      'X-Page',
      'X-Per-Page',
      'X-Next-Page',
      'X-Prev-Page'
    ]

    config.middleware.insert_before 0, Rack::Cors, :debug => true, :logger => (-> { Rails.logger }) do
      allow do
        origins cors_origins

        resource '*',
          :headers => :any,
          :expose => pagination_headers,
          :methods => [:get, :post, :delete, :put, :options, :head],
          :max_age => 0
      end
    end
    # Neo4j using Graph Story
    config.neo4j.wait_for_connection = true
    config.neo4j.session.type = :http
    config.neo4j.session.path = ENV["GRAPHENEDB_URL"]

    # ActiveJob using Sneakers(RabbitMQ)
    config.active_job.queue_adapter = ENV['ACTIVE_JOB_QUEUE_ADAPTER'] || :sneakers
    config.active_job.queue_name_prefix = Rails.env
    config.active_job.queue_name_delimiter = '.'
  end
end
