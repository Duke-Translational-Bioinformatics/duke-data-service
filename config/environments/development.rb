Rails.application.configure do
  config.cache_classes = ENV['RAILS_CACHE_CLASSES'].present?
  config.eager_load = ENV['RAILS_EAGER_LOAD'].present?
  config.consider_all_requests_local       = ENV['RAILS_CONSIDER_REQUESTS_LOCAL'].present?
  config.action_controller.perform_caching = ENV['RAILS_PERFORM_CACHING'].present?
  config.serve_static_files = ENV['RAILS_SERVE_STATIC_FILES'].present?
  config.assets.js_compressor = :uglifier
  config.assets.compile = false
  config.assets.digest = true
  config.assets.debug = false
  config.assets.raise_runtime_errors = false
  config.action_mailer.raise_delivery_errors = false
  config.active_support.deprecation = :log
  config.active_record.migration_error = :page_load
  unless ENV['NOFORCESSL'].present?
    config.force_ssl = true
  end
end
