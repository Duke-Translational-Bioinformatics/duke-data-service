source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.1'
# Use postgresql as the database for Active Record
gem 'pg'
# Use puma as the webserver in development
gem 'puma'
gem 'rack', '1.6.4'
gem 'rack-cors', :require => 'rack/cors'
gem 'grape-swagger'
gem 'kaminari'
gem 'grape-kaminari'

gem 'jwt'
gem 'grape'
gem "hashie-forbidden_attributes" #overrides strong_params in grape endpoints
gem "grape-active_model_serializers"
gem 'turbolinks'
gem 'uglifier'
gem 'pundit'
gem 'httparty'

# use figaro to set heroku environment variables for secrets
gem 'figaro'

# circle-ci metadata formatter
gem 'rspec_junit_formatter', '0.2.2'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development do
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
end

group :development, :test do
  gem "factory_girl_rails"
  gem "faker"
  gem 'rspec-rails'
end

group :test do
  gem 'shoulda-matchers', require: false
  gem 'spring-commands-rspec'
  gem 'vcr', group: :test
  gem 'webmock', group: :test
  gem 'pry-byebug'
end

#heroku requires this
gem 'rails_12factor', group: :production
ruby "2.2.2"
