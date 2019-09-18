Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = ENV['RAILS_CACHE_CLASSES'].present?

  # Do not eager load code on boot.
  config.eager_load = ENV['RAILS_EAGER_LOAD'].present?

  # Show full error reports.
  config.consider_all_requests_local       = ENV['RAILS_CONSIDER_REQUESTS_LOCAL'].present?

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp', 'caching-dev.txt').exist?
    config.action_controller.perform_caching = ENV['RAILS_PERFORM_CACHING'].present?

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Store uploaded files on the local file system (see config/storage.yml for options)
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = ENV['RAILS_MAILER_ERRORS'].present?

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load
  config.force_ssl = true

  # :debug :info :warn :error :fatal :unknown (0-5)
  config.log_level = ENV['RAILS_LOG_LEVEL'] || :debug


  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  config.assets.js_compressor = :uglifier
  config.assets.compile = ENV['RAILS_COMPILE_ASSETS'].present?
  config.assets.digest = ENV['RAILS_DIGEST_ASSETS'].present?
  config.assets.raise_runtime_errors = ENV['RAILS_ERRORS_ASSETS'].present?

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = ENV['RAILS_DEBUG_ASSETS'].present?

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker
end
