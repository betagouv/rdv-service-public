# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.2"

gem "dotenv-rails" # dotenv should always be loaded before rails

# Standard Rails stuff
gem "rails", "~> 7.0.4"
gem "sprockets-rails"
gem "puma", "< 6.0" # Until Puma stops returning HTTP 501 on PROPFIND requests: https://github.com/puma/puma/issues/3014
gem "jsbundling-rails"
gem "turbolinks", "~> 5"
gem "bootsnap", require: false # Reduces boot times through caching; required in config/boot.rb
gem "rack-cors" # CORS management
gem "mail"

# Ops
gem "sentry-ruby"
gem "sentry-rails"
gem "skylight"
gem "rack-attack"

# Database
gem "pg"
gem "pg_search"
gem "kaminari"
gem "bootstrap4-kaminari-views"
gem "administrate"
# TODO: migrate columns to json before upgrading to v13 (https://github.com/paper-trail-gem/paper_trail/blob/master/doc/pt_13_yaml_safe_load.md)
gem "paper_trail", "< 13.0"
gem "activerecord-postgres_enum"
gem "redis", "< 5.0"
gem "redis-session-store", "0.11.4"
gem "hiredis"

# Devise / auth
gem "devise"
gem "devise_invitable"
gem "devise-async"
gem "omniauth-github"
gem "omniauth-microsoft_graph"
gem "omniauth_openid_connect"
gem "omniauth-rails_csrf_protection"
gem "pundit"
gem "devise_token_auth"

# Jobs
gem "good_job"
gem "daemons"

# JSON serialization and queries
gem "jbuilder"
gem "blueprinter"
gem "typhoeus"

# API documentation
gem "rswag-api"
gem "rswag-ui"

# Form
gem "simple_form", "~> 5.0"
gem "phonelib"
gem "auto_strip_attributes"

# Frontend
gem "slim"
gem "chartkick", "~> 5.0.1"
gem "groupdate", "~> 6.1"
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

gem "lograge"

group :development, :test do
  gem "active_record_doctor"
  gem "byebug", platforms: %i[mri mingw x64_mingw] # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "brakeman", require: false
  gem "rubocop", "1.24.1", require: false
  gem "rubocop-rspec", "2.7.0"
  gem "rubocop-rails", "2.13.1"
  gem "rspec-rails"
  gem "rspec_junit_formatter", require: false
  gem "rails-controller-testing"
  gem "factory_bot"
  gem "bullet"
  gem "faker"
  gem "parallel_tests"
  gem "simplecov", require: false
  gem "slim_lint", require: false
  # New versions of axe are more strict
  gem "axe-core-api", "4.3.2"
  gem "axe-core-rspec", "4.3.2"
  gem "selenium-webdriver"
  gem "spring", require: false
  gem "spring-commands-rspec"
  gem "rswag-specs"
end

group :development do
  gem "listen" # Needed for ActiveSupport::EventedFileUpdateChecker. See config/environment/development.rb
  gem "better_errors" # Better error page than the Rails default
  gem "binding_of_caller" # Enable the REPL in better_errors
  gem "letter_opener_web" # Saves sent emails and serves them on /letter_opener
  gem "rails-erd" # Keeps docs/domain_model.svg up-to-date. See .erdconfig
  gem "rack-mini-profiler"
end

group :test do
  gem "capybara"
  gem "capybara-email"
  gem "capybara-screenshot"
  gem "webdrivers"
  gem "database_cleaner"
  gem "webmock"
end
