source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.2'

gem 'dotenv-rails', '~> 2.7.2' # dotenv should always be loaded before rails
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.3'
# Use Puma as the app server
gem 'puma', '~> 3.11'

# DB
gem 'pg', '>= 0.18', '< 2.0'
gem 'pg_search', '~> 2.2'
gem 'kaminari', '~> 1.1'
gem 'bootstrap4-kaminari-views'
gem 'administrate', '~> 0.11'

# Devise / auth
gem 'devise', '~> 4.6'
gem 'devise_invitable', '~> 2.0'
gem 'devise-async', '~> 1.0'
gem 'omniauth-github'
gem 'pundit', '~> 2.0'

# Jobs
gem 'delayed_job_active_record'
gem 'delayed_job_web'

# Form
gem 'simple_form', '~> 4.1'
gem 'actiontext', github: 'kobaltz/actiontext', branch: 'archive', require: 'action_text'
gem 'image_processing', '~> 1.8'

# Front
gem 'sass-rails', '~> 5.0'
gem 'bootstrap', '~> 4.3'
gem 'autoprefixer-rails', '~> 9.6'
gem 'font-awesome-rails', '~> 4.7'
gem "chartkick", '~> 3.2.0'
gem 'uglifier', '>= 1.3.0'
gem 'slim', '~> 4.0'
gem 'jquery-rails', '~> 4.3'
gem 'holder_rails'
gem 'icalendar', '~> 2.5'
gem 'select2-rails', '~> 4.0'
gem 'momentjs-rails', '~> 2.8'
gem 'bootstrap-daterangepicker-rails', '~> 3.0'
gem "montrose", '~> 0.9'
gem 'tod', '~> 2.2'

# Mailing
gem 'sendgrid', '~> 1.2.4'
gem 'premailer-rails', '~> 1.10'

# Ops
gem 'airbrake', '~> 9.2'

# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'webpacker'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'mini_racer', platforms: :ruby

# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'brakeman', require: false
  gem 'rubocop', require: false
  gem 'rspec-rails', '~> 3.8'
  gem 'factory_bot'
  gem 'meta_request', '~> 0.7'
  gem 'bullet'
  gem 'faker'
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
  gem 'xray-rails'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'letter_opener', '~> 1.7'
  gem 'fuubar'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
  # Easy installation and use of chromedriver to run system tests with Chrome
  gem 'chromedriver-helper'
  gem 'database_cleaner'
  gem 'timecop'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
