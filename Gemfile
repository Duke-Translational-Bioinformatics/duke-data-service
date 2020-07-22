source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.0'

gem 'rack', '~> 2.1.0'

# Use postgresql as the database for Active Record
gem "pg"

# Use neo4j for PROV graph relationships
gem 'neo4j', '~> 9.0'

# Use sneakers(RabbitMQ) for background jobs
gem 'sneakers', '~> 2.11.0'
gem 'sneakers_handlers', '~> 0.0.6'

# User ldap for ldap_identity_provider searches
gem 'net-ldap'

# Use puma as the webserver in development
gem 'puma'
gem 'rack-cors', :require => 'rack/cors'
gem "rack-timeout"

gem 'grape-swagger'
gem 'grape_logging'
gem 'kaminari'
gem 'kaminari-grape' #needed for kaminari 1.x
gem 'grape-kaminari'

# Use elasticsearch for search
# must be included after kaminari according to elasticsearch-model documentation
gem 'elasticsearch', '~> 5.0'
gem 'elasticsearch-model', '~> 5.0'
gem 'elasticsearch-rails', '~> 5.0'


# Auditing
gem 'audited'

# Unions in policy scopes
gem 'active_record_union'

gem 'jwt'
gem 'grape'
gem "hashie-forbidden_attributes" #overrides strong_params in grape endpoints
gem "grape-active_model_serializers"
gem 'turbolinks'
gem 'uglifier'
gem 'pundit'
gem 'httparty'

# AWS S3 Support
gem 'aws-sdk-s3'

# use heroku platform-api to set heroku environment variables for secrets
gem 'platform-api'
gem 'netrc'

# circle-ci metadata formatter
gem 'rspec_junit_formatter'

# newrelic agent
# https://docs.newrelic.com/docs/agents/ruby-agent/installation-configuration/ruby-agent-installation
gem 'newrelic_rpm'

gem "factory_bot_rails"
gem "faker"

group :bots do
  # Bot Gems
  gem "octokit", "~> 4.0"
end

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :docker do
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
end

group :development, :docker, :test do
  gem 'rspec-rails'
  gem 'rspec-activemodel-mocks'
end

group :docker, :test do
  gem 'pry-byebug'
end

group :test do
  gem 'rails-controller-testing'
  gem 'shoulda-matchers', require: false
  gem 'shoulda-callback-matchers', '~> 1.1', '>= 1.1.3'
  gem 'spring-commands-rspec'
  gem 'vcr'
  gem 'webmock'
  gem 'bunny-mock'
  gem 'simplecov', require: false
end

group :docker do
  gem "rails-erd"
end

#heroku requires this
group :docker, :development, :ua_test, :production do
  gem 'rails_12factor'
end
ruby "2.6.4"
