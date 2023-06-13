# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.2"

# Autoload dotenv in Rails.
gem "dotenv-rails" # dotenv should always be loaded before rails

# Full-stack web application framework.
gem "rails", "~> 7.0.5"
# Rack-based asset packaging system
gem "sprockets-rails"
# Puma is a simple, fast, threaded, and highly parallel HTTP 1.1 server for Ruby/Rack applications
gem "puma", "< 6.0" # Lock < 6.O until Puma stops returning HTTP 501 on PROPFIND requests: https://github.com/puma/puma/issues/3014
# Bundle and transpile JavaScript in Rails with esbuild, rollup.js, or Webpack.
gem "jsbundling-rails"
# Turbolinks makes navigating your web application faster
gem "turbolinks", "~> 5"
# Boot large ruby/rails apps faster
gem "bootsnap", require: false # Reduces boot times through caching; required in config/boot.rb
# Middleware for enabling Cross-Origin Resource Sharing in Rack apps
gem "rack-cors" # CORS management
# Mail provides a nice Ruby DSL for making, sending and reading emails.
gem "mail"

# Ops
# A gem that provides a client interface for the Sentry error logger
gem "sentry-ruby"
# A gem that provides Rails integration for the Sentry error logger
gem "sentry-rails"
# Skylight is a smart profiler for Rails, Sinatra, and other Ruby apps.
gem "skylight"
# Block & throttle abusive requests
gem "rack-attack"

# Database
# Pg is the Ruby interface to the PostgreSQL RDBMS
gem "pg"
# PgSearch builds Active Record named scopes that take advantage of PostgreSQL's full text search
gem "pg_search"
# A pagination engine plugin for Rails 4+ and other modern frameworks
gem "kaminari"
# Bootstrap 4 styling for Kaminari gem
gem "bootstrap4-kaminari-views"
# A Rails engine for creating super-flexible admin dashboards
gem "administrate"
# TODO: migrate columns to json before upgrading to v13 (https://github.com/paper-trail-gem/paper_trail/blob/master/doc/pt_13_yaml_safe_load.md)
# Track changes to your models.
gem "paper_trail", "< 13.0"
# Integrate PostgreSQL's enum data type into ActiveRecord's schema and migrations.
gem "activerecord-postgres_enum"
# A Ruby client library for Redis
gem "redis", "< 5.0"
# A drop-in replacement for e.g. MemCacheStore to store Rails sessions (and Rails sessions only) in Redis.
gem "redis-session-store", "0.11.4"
# Ruby wrapper for hiredis (protocol serialization/deserialization and blocking I/O)
gem "hiredis"

# Devise / auth
# Flexible authentication solution for Rails with Warden
gem "devise"
# An invitation strategy for Devise
gem "devise_invitable"
# Deliver Devise's emails in the background using ActiveJob.
gem "devise-async"
# Official OmniAuth strategy for GitHub.
gem "omniauth-github"
# omniauth provider for Microsoft Graph
gem "omniauth-microsoft_graph"
# OpenID Connect Strategy for OmniAuth
gem "omniauth_openid_connect"
# Provides CSRF protection on OmniAuth request endpoint on Rails application.
gem "omniauth-rails_csrf_protection"
# OO authorization for Rails
gem "pundit"
# Token based authentication for rails. Uses Devise + OmniAuth.
gem "devise_token_auth"

# Jobs
# A multithreaded, Postgres-based ActiveJob backend for Ruby on Rails
gem "good_job"
# A toolkit to create and control daemons in different ways
gem "daemons"

# JSON serialization and queries

# Create JSON structures via a Builder-style DSL
gem "jbuilder"
# Simple Fast Declarative Serialization Library
gem "blueprinter"
# Parallel HTTP library on top of libcurl multi.
gem "typhoeus"

# API documentation

# A Rails Engine that exposes OpenAPI (formerly called Swagger) files as JSON endpoints
gem "rswag-api"
# A Rails Engine that includes swagger-ui and powers it from configured OpenAPI (formerly named Swagger) endpoints
gem "rswag-ui"

# Forms

# Forms made easy!
gem "simple_form", "~> 5.0"
# Gem validates phone numbers with Google libphonenumber database
gem "phonelib"
# Removes unnecessary whitespaces in attributes. Extension to ActiveRecord or ActiveModel.
gem "auto_strip_attributes"

# Frontend

# Slim is a template language.
gem "slim"
# Create beautiful JavaScript charts with one line of Ruby
gem "chartkick", "~> 5.0.1"
# The simplest way to group temporal data
gem "groupdate", "~> 6.1"
# Automatic generation of html links in texts
gem "rails_autolink"
# ActionView helper to render currently active links
gem "active_link_to"
gem "dsfr-view-components"

# Easily create styled HTML emails in Rails.
gem "premailer-rails" # Mail formatting
# SendinBlue API V3 Ruby Gem
gem "sib-api-v3-sdk" # SendInBlue (SMS)
# The Spreadsheet Library is designed to read and write Spreadsheet Documents
gem "spreadsheet" # Excel export
# If string, numeric, symbol and nil values wanna be a boolean value, they can with the new #to_b method (and more).
gem "wannabe_bool" # imports to_b method
gem "rubyzip" # zip export files

## Time Management

# Recurring events in Ruby
gem "montrose"
# Supplies TimeOfDay and Shift class
gem "tod", "~> 2.2"
# A ruby implementation of the iCalendar specification (RFC-5545).
gem "icalendar", "~> 2.5"

# Tame Rails' multi-line logging into a single line per request
gem "lograge"

group :development, :test do
  # Identify database issues before they hit production.
  gem "active_record_doctor"
  # Ruby fast debugger - base + CLI
  gem "byebug", platforms: %i[mri mingw x64_mingw] # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  # Security vulnerability scanner for Ruby on Rails.
  gem "brakeman", require: false
  # Automatic Ruby code style checking tool.
  gem "rubocop", "1.24.1", require: false
  # Code style checking for RSpec files
  gem "rubocop-rspec", "2.7.0"
  # Automatic Rails code style checking tool.
  gem "rubocop-rails", "2.13.1"
  # RSpec for Rails
  gem "rspec-rails"
  # RSpec JUnit XML formatter
  gem "rspec_junit_formatter", require: false
  # Extracting `assigns` and `assert_template` from ActionDispatch.
  gem "rails-controller-testing"
  # factory_bot provides a framework and DSL for defining and using model instance factories.
  gem "factory_bot"
  # help to kill N+1 queries and unused eager loading.
  gem "bullet"
  # Easily generate fake data
  gem "faker"
  # Run Test::Unit / RSpec / Cucumber / Spinach in parallel
  gem "parallel_tests"
  # Code coverage for Ruby
  gem "simplecov", require: false
  # Slim template linting tool
  gem "slim_lint", require: false
  # Axe API utility methods
  gem "axe-core-api", "4.3.2" # Fixed to 4.3.2 because recent versions of axe are more strict
  # RSpec custom matchers for Axe
  gem "axe-core-rspec", "4.3.2"
  # Selenium is a browser automation tool for automated testing of webapps and more
  gem "selenium-webdriver"
  # Rails application preloader
  gem "spring", require: false
  # rspec command for spring
  gem "spring-commands-rspec"
  # An OpenAPI-based (formerly called Swagger) DSL for rspec-rails & accompanying rake task for generating OpenAPI specification files
  gem "rswag-specs"
end

group :development do
  # Listen to file modifications
  gem "listen" # Needed for ActiveSupport::EventedFileUpdateChecker. See config/environment/development.rb
  # Better error page for Rails and other Rack apps
  gem "better_errors"
  # Retrieve the binding of a method's caller, or further up the stack.
  gem "binding_of_caller" # Enable the REPL in better_errors
  # Gives letter_opener an interface for browsing sent emails
  gem "letter_opener_web" # Saves sent emails and serves them on /letter_opener
  # Entity-relationship diagram for your Rails models.
  gem "rails-erd" # Keeps docs/domain_model.svg up-to-date. See .erdconfig
  # Profiles loading speed for rack applications.
  gem "rack-mini-profiler"
end

group :test do
  # Capybara aims to simplify the process of integration testing Rack applications, such as Rails, Sinatra or Merb
  gem "capybara"
  # Test your ActionMailer and Mailer messages in Capybara
  gem "capybara-email"
  # Automatically create snapshots when Cucumber steps fail with Capybara and Rails
  gem "capybara-screenshot"
  # Easy download and use of browser drivers.
  gem "webdrivers"
  # Strategies for cleaning databases. Can be used to ensure a clean slate for testing.
  gem "database_cleaner"
  # Library for stubbing HTTP requests in Ruby.
  gem "webmock"
end
