# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'simplecov'

ENV['RAILS_ENV'] ||= 'test'
require 'spec_helper'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!
require 'shoulda-matchers'
require 'vcr'
require 'pundit/rspec'
require 'uri'
require 'bunny-mock'

# Load rake tasks so they can be tested.
Rake.application = Rake::Application.new
Rails.application.load_tasks

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Provides helper methods for testing Active Job
  include ActiveJob::TestHelper

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  SNEAKERS_CONFIG_ORIGINAL = Sneakers::CONFIG.dup
  config.before(:suite) do
    ElasticsearchHandler.new.drop_indices
  end
  config.before(:context) do
    ActiveJob::Base.queue_adapter = :test
  end
  config.after(:each) do
    ActiveJob::Base.queue_adapter = :test
  end
  config.before(:suite) do
    Sneakers::CONFIG[:connection].start if ENV['TEST_WITH_BUNNY']
  end
  config.after(:each) do
    Neo4j::ActiveBase.current_session.query('MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r')
  end
  config.after(:each) do
    Audited.store.clear
  end
end

# FactoryBot 5.0.0 Changed: use_parent_strategy now defaults to true, so by default the build strategy will build, rather than create associations
# Overriding this default until tests/code are changed
FactoryBot.use_parent_strategy = false

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.ignore_hosts URI(Rails.application.config.neo4j.session.path).host,
                 ENV['BONSAI_URL'].split(':').first,
                 URI(ENV['OPENID_URL']).host
  c.register_request_matcher :header_keys do |request_1, request_2|
    request_1.headers.keys == request_2.headers.keys
  end

  c.register_request_matcher :uri_ignoring_uuids do |request_1, request_2|
    uuid = /\h{8}-\h{4}-\h{4}-\h{4}-\h{12}/
    request_1.uri.gsub(uuid, 'uuid') == request_2.uri.gsub(uuid, 'uuid')
  end

  c.default_cassette_options = {
    match_requests_on: [:method, :uri_ignoring_uuids, :header_keys ]
  }
end

# Mocking Bunny for Sneakers ActiveJob testing
BunnyMock.use_bunny_queue_pop_api = true
module BunnyMock
  class Queue
    def durable?
      opts[:durable]
    end

    def cancel
      @consumers = []
      self
    end

    def consumer_tag
      'the-consumer-tag'
    end

    def pop(opts = { manual_ack: false }, &block)
      r = bunny_pop(opts, &block)
      store_acknowledgement(r, [opts])
      r
    end
  end

  class Exchange
    def add_route(key, xchg_or_queue)
      @routes[key] ||= []
      @routes[key] << xchg_or_queue unless @routes[key].include?(xchg_or_queue)
    end
  end
end
