# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.1.1"

gem "dotenv-rails" # dotenv should always be loaded before rails

# Standard Rails stuff
gem "rails", "~> 6.0"
gem "sprockets-rails"
gem "puma"
gem "jsbundling-rails"
gem "turbolinks", "~> 5"
gem "bootsnap", require: false # Reduces boot times through caching; required in config/boot.rb
gem "rack-cors" # CORS management

# Temporarily fixed versions
# This RC version supports Ruby 3.1 ()https://github.com/mikel/mail/commit/d9d8dcc)
gem "mail", "2.8.0.rc1"

# Ops
gem "sentry-ruby"
gem "sentry-rails"
gem "skylight"

# Database
gem "pg"
gem "pg_search"
gem "kaminari"
gem "bootstrap4-kaminari-views"
gem "administrate", git: "https://github.com/thoughtbot/administrate.git", ref: "refs/pull/1972/head" # Provides an administration UI (pull request #1972 has fixes for Rails 6.1.3.2)
gem "administrate-field-belongs_to_search"
gem "paper_trail"
gem "activerecord-postgres_enum"
gem "redis"
gem "hiredis"

# Devise / auth
gem "devise"
gem "devise_invitable"
gem "devise-async"
gem "omniauth-github"
gem "omniauth_openid_connect"
gem "omniauth-rails_csrf_protection"
gem "pundit"
gem "devise_token_auth", github: "lynndylanhurley/devise_token_auth"

# Jobs
gem "delayed_job_active_record"
gem "delayed_job_web"
gem "delayed_cron_job"
gem "daemons"

# JSON serialization and queries
gem "jbuilder"
gem "blueprinter"
gem "typhoeus"

# Form
gem "simple_form", "~> 5.0"
gem "phonelib"
gem "auto_strip_attributes"

# Frontend
gem "slim"
gem "chartkick", "~> 3.4.0"
gem "groupdate", "~> 4.2"
gem "rails_autolink"
gem "active_link_to"

gem "premailer-rails" # Mail formatting
gem "sib-api-v3-sdk" # SendInBlue (SMS)
gem "spreadsheet" # Excel export
gem "wannabe_bool" # imports to_b method

## Time Management
gem "montrose"
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
  gem "axe-core-rspec"
  gem "selenium-webdriver"
  gem "spring", require: false
  gem "spring-commands-rspec"
end

group :development do
  gem "listen" # Needed for ActiveSupport::EventedFileUpdateChecker. See config/environment/development.rb
  gem "better_errors" # Better error page than the Rails default
  gem "binding_of_caller" # Enable the REPL in better_errors
  gem "letter_opener_web" # Saves sent emails and serves them on /letter_opener
  gem "rails-erd" # Keeps docs/domain_model.png up-to-date. See .erdconfig
end

group :test do
  gem "capybara"
  gem "capybara-email"
  gem "capybara-screenshot"
  gem "webdrivers", "~> 4.6.0"
  gem "database_cleaner"
  gem "webmock"
end
