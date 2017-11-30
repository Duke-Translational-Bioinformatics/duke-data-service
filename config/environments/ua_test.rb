Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  if Rails.version > '5.0.0'
    config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?
  else
    config.serve_static_files = ENV['RAILS_SERVE_STATIC_FILES'].present?
  end
  config.assets.js_compressor = :uglifier
  config.assets.compile = false
  config.assets.digest = true

  # :debug :info :warn :error :fatal :unknown (0-5)
  config.log_level = ENV['RAILS_LOG_LEVEL'] || :info

  config.i18n.fallbacks = true
  config.active_support.deprecation = :notify
  config.log_formatter = ::Logger::Formatter.new
  config.active_record.dump_schema_after_migration = false
  config.force_ssl = true
end
