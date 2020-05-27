source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.0'

gem 'dotenv-rails', '~> 2.7.2' # dotenv should always be loaded before rails
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0'
gem 'sprockets-rails'

# Use Puma as the app server
gem 'puma', '~> 3.12'

# DB
gem 'pg', '>= 0.18', '< 2.0'
gem 'pg_search', '~> 2.3'
gem 'kaminari', '~> 1.1'
gem 'bootstrap4-kaminari-views', '~> 1.0'
gem 'administrate', github: 'thoughtbot/administrate', branch: 'master' # to use PR #1579
gem 'administrate-field-belongs_to_search', '~> 0.7'
gem 'paper_trail'
gem 'flipflop'

# Devise / auth
gem 'devise', '~> 4.7'
gem 'devise_invitable', '~> 2.0'
gem 'devise-async', '~> 1.0'
gem 'omniauth-github', '~> 1.4'
gem 'pundit', '~> 2.0'

# Jobs
gem 'delayed_job_active_record', '~> 4.1.4'
gem 'delayed_job_web'
gem 'delayed_cron_job'
gem 'daemons'

# Form
gem 'simple_form', '~> 5.0'
gem 'image_processing', '~> 1.8'
gem 'phonelib'

# Front
gem "chartkick", '~> 3.3.0'
gem 'groupdate', '~> 4.2'
gem 'slim', '~> 4.0'

## Time Management
gem 'montrose', '~> 0.11.2'
gem 'tod', '~> 2.2'
gem 'icalendar', '~> 2.5'

# Mailing
gem 'premailer-rails'

# SMS
gem 'twilio-ruby', '~> 5.29.1'

# Web Hook
gem 'blueprinter'
gem 'typhoeus'

# Ops
gem "sentry-raven"
gem "skylight"

gem "js-routes"

gem 'webpacker'

gem 'turbolinks', '~> 5'
gem 'jbuilder', '~> 2.5'
gem 'bootsnap', '>= 1.1.0', require: false
gem 'spreadsheet'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'brakeman', require: false
  gem 'rubocop', require: false
  gem 'rspec-rails', '>= 4.0.0.beta'
  gem 'rspec_junit_formatter', require: false
  gem 'rails-controller-testing'
  gem 'factory_bot'
  gem 'meta_request', '~> 0.7'
  gem 'bullet'
  gem 'faker'
  gem 'parallel_tests'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'guard-rspec', require: false
  gem 'guard-spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'letter_opener', '~> 1.7'
  gem 'fuubar'
  gem 'better_errors'
  gem 'binding_of_caller'
end

group :test do
  gem 'capybara', '>= 2.15'
  gem 'capybara-selenium'
  gem 'capybara-email'
  gem 'capybara-screenshot'
  gem 'webdrivers', '~> 4.0'
  gem 'database_cleaner'
end
