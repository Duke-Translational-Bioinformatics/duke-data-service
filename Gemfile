source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.1' # Remove in rails 5
#gem 'rails', '~> 5.0' # Needed in rails 5
# Use postgresql as the database for Active Record
gem 'pg'

# Use neo4j for PROV graph relationships
gem 'neo4j'

# Use elasticsearch for search
gem 'elasticsearch-model'
gem 'elasticsearch-rails'

# Use puma as the webserver in development
gem 'puma'
gem 'rack', '1.6.4' # Remove in rails 5
gem 'rack-cors', :require => 'rack/cors'
gem 'grape-middleware-lograge'

gem 'grape-swagger'
gem 'kaminari'
gem 'grape-kaminari'

# Auditing
gem "audited-activerecord"
#gem "rails-observers", github: 'rails/rails-observers' # Needed in rails 5
#gem 'audited', github: 'collectiveidea/audited' # Needed in rails 5

# Unions in policy scopes
gem 'active_record_union'

# portal
gem 'sinatra' # Remove in rails 5

gem 'jwt'
gem 'grape'
gem "hashie-forbidden_attributes" #overrides strong_params in grape endpoints
gem 'active_model_serializers', '~> 0.9.0'
gem "grape-active_model_serializers"
gem 'turbolinks'
gem 'uglifier'
gem 'pundit'
gem 'httparty'

# use heroku platform-api to set heroku environment variables for secrets
gem 'platform-api'
gem 'netrc'

# circle-ci metadata formatter
gem 'rspec_junit_formatter', '0.2.2'

# newrelic agent
# https://docs.newrelic.com/docs/agents/ruby-agent/installation-configuration/ruby-agent-installation
gem 'newrelic_rpm'

gem "factory_girl_rails"
gem "faker"

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :docker do
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
end

group :development, :docker, :test do
  gem 'rspec-rails'
end

group :test do
  #gem 'rails-controller-testing' # Needed in rails 5
  gem 'shoulda-matchers', require: false
  gem 'shoulda-callback-matchers', '~> 1.1', '>= 1.1.3'
  gem 'spring-commands-rspec'
  gem 'vcr'
  gem 'webmock'
  gem 'pry-byebug'
  gem 'simplecov', :require => false, :group => :test
end

#heroku requires this
group :docker, :development, :ua_test, :production do
  gem 'rails_12factor'
end
ruby "2.2.2"
