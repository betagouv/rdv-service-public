# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "2.7.3"

gem "dotenv-rails", "~> 2.7.2" # dotenv should always be loaded before rails

# Standard Rails stuff
gem "rails", "~> 6.0"
gem "sprockets-rails"
gem "puma", "~> 4.3"
gem "webpacker"
gem "turbolinks", "~> 5"

gem "bootsnap", ">= 1.1.0", require: false # Reduces boot times through caching; required in config/boot.rb
gem "rack-cors" # CORS management

# Ops
gem "sentry-ruby"
gem "sentry-rails"
gem "skylight"

# Database
gem "pg", ">= 0.18", "< 2.0"
gem "pg_search", "~> 2.3"
gem "kaminari", "~> 1.2"
gem "bootstrap4-kaminari-views", "~> 1.0"
gem "administrate", git: "https://github.com/thoughtbot/administrate.git", ref: "refs/pull/1972/head" # Provides an administration UI (pull request #1972 has fixes for Rails 6.1.3.2)
gem "administrate-field-belongs_to_search"
gem "paper_trail"
gem "activerecord-postgres_enum"

# Devise / auth
gem "devise", "~> 4.7"
gem "devise_invitable", "~> 2.0"
gem "devise-async", "~> 1.0"
gem "omniauth-github", "~> 1.4"
gem "omniauth_openid_connect"
gem "omniauth-rails_csrf_protection", "~> 0.1"
gem "pundit", "~> 2.0"
gem "devise_token_auth", github: "lynndylanhurley/devise_token_auth"

# Jobs
gem "delayed_job_active_record", "~> 4.1.4"
gem "delayed_job_web"
gem "delayed_cron_job"
gem "daemons"

# JSON serialization and queries
gem "jbuilder", "~> 2.5"
gem "blueprinter"
gem "typhoeus"

# Form
gem "simple_form", "~> 5.0"
gem "image_processing", "~> 1.8"
gem "phonelib"
gem "activemodel-caution", github: "rdv-solidarites/activemodel-caution"
gem "auto_strip_attributes"

# Frontend
gem "slim", "~> 4.0"
gem "chartkick", "~> 3.4.0"
gem "groupdate", "~> 4.2"
gem "rails_autolink"

gem "premailer-rails" # Mail formatting
gem "sib-api-v3-sdk" # SendInBlue (SMS)
gem "spreadsheet" # Excel export

## Time Management
gem "montrose", "~> 0.11.2"
gem "tod", "~> 2.2"
gem "icalendar", "~> 2.5"

group :development, :test do
  gem "byebug", platforms: %i[mri mingw x64_mingw] # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "brakeman", require: false
  gem "rubocop", require: false
  gem "rubocop-rspec"
  gem "rubocop-rails"
  gem "rspec-rails"
  gem "rspec_junit_formatter", require: false
  gem "rails-controller-testing"
  gem "factory_bot"
  gem "meta_request"
  gem "bullet"
  gem "faker"
  gem "parallel_tests"
  gem "simplecov", require: false
  gem "slim_lint", require: false
end

group :development do
  gem "listen" # Needed for ActiveSupport::EventedFileUpdateChecker. See config/environment/development.rb
  gem "better_errors" # Better error page than the Rails default
  gem "letter_opener_web" # Saves sent emails and serves them on /letter_opener
  gem "rails-erd" # Keeps docs/domain_model.png up-to-date. See .erdconfig
end

group :test do
  gem "capybara"
  gem "capybara-email"
  gem "capybara-screenshot"
  gem "webdrivers"
  gem "database_cleaner"
end
