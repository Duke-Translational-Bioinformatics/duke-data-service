source 'https://rubygems.org'

ruby '2.2.2'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.1'
# Use postgresql as the database for Active Record
gem 'pg'
# Use thin as the webserver in development
gem 'thin'

gem 'jwt'
gem 'grape'
gem "hashie-forbidden_attributes" #overrides strong_params in grape endpoints
gem "grape-active_model_serializers"
gem 'react-rails'
gem 'tilt'
gem 'jquery-rails'
gem 'turbolinks'

# use figaro to set heroku environment variables for secrets
gem 'figaro'

# circle-ci metadata formatter
gem 'rspec_junit_formatter', '0.2.2'

#heroku requires this
gem 'rails_12factor', group: :production

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem "factory_girl_rails"
  gem "faker"
  gem 'rspec-rails'
  gem 'shoulda-matchers', require: false
  gem 'spring-commands-rspec', group: :development
end
