source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.4.8"

# Full-stack web application framework.
gem "rails", "8.0.4"
# Rack-based asset packaging system
gem "sprockets-rails"
# Puma is a simple, fast, threaded, and highly parallel HTTP 1.1 server for Ruby/Rack applications
gem "puma"
# Bundle and transpile JavaScript in Rails with esbuild, rollup.js, or Webpack.
gem "jsbundling-rails"
# Boot large ruby/rails apps faster
gem "bootsnap", require: false # Reduces boot times through caching; required in config/boot.rb
# Middleware for enabling Cross-Origin Resource Sharing in Rack apps
gem "rack-cors" # CORS management
# Mail provides a nice Ruby DSL for making, sending and reading emails.
gem "mail"

# Hotwire
gem "hotwire-rails" # Hotwire is a framework for building modern web applications without using much JavaScript

# Ops
# A gem that provides a client interface for the Sentry error logger
gem "sentry-ruby"
# A gem that provides Rails integration for the Sentry error logger
gem "sentry-rails"
# Skylight is a smart profiler for Rails, Sinatra, and other Ruby apps.
gem "skylight"
# Block & throttle abusive requests
gem "rack-attack"
# Dépendance interne pour anonymiser les records AR
gem "anonymizer", path: "lib/anonymizer"

# Database
# Pg is the Ruby interface to the PostgreSQL RDBMS
gem "pg"
# PgSearch builds Active Record named scopes that take advantage of PostgreSQL's full text search
gem "pg_search"
# Strong Migrations catches unsafe migrations in development
gem "strong_migrations"
# A pagination engine plugin for Rails 4+ and other modern frameworks
gem "kaminari"
# A Rails engine for creating super-flexible admin dashboards
gem "administrate"
# Track changes to your models.
gem "paper_trail"
# A Ruby client library for Redis
gem "redis"
# Adds a Redis::Namespace class which can be used to namespace calls to Redis.
gem "redis-namespace"
# Generic connection pooling for Ruby
gem "connection_pool"

# Devise / auth
# Flexible authentication solution for Rails with Warden
gem "devise", git: "https://github.com/victormours/devise", ref: "0c502c8ab7f11e03ece9d9552cdf5d96e22c40c6"
# An invitation strategy for Devise
gem "devise_invitable"
# Deliver Devise's emails in the background using ActiveJob.
gem "devise-async"
# omniauth provider for Microsoft Graph
gem "omniauth-microsoft_graph"
# omniauth provider for inter-instance migrations
gem "omniauth-rdv-service-public", path: "lib/omniauth-rdv-service-public"

# OpenID Connect Strategy for OmniAuth
gem "omniauth_openid_connect"
# Oauth provider
gem "doorkeeper"
# Translations for Doorkeeper
gem "doorkeeper-i18n"
# Provides CSRF protection on OmniAuth request endpoint on Rails application.
gem "omniauth-rails_csrf_protection"
# OO authorization for Rails
gem "pundit"
# Token based authentication for rails. Uses Devise + OmniAuth.
gem "devise_token_auth", "1.2.5"
# List of frequently used passwords
gem "common_french_passwords"

# Jobs
# A multithreaded, Postgres-based ActiveJob backend for Ruby on Rails
gem "good_job", "3.27.4"

# JSON serialization and queries

# A simple and fast JSON API template engine for Ruby on Rails
gem "jb"
# Simple Fast Declarative Serialization Library
gem "blueprinter"
# Parallel HTTP library on top of libcurl multi.
gem "typhoeus"

# External services
gem "notion-ruby-client", "~> 1.2"

# API documentation

# A Rails Engine that exposes OpenAPI (formerly called Swagger) files as JSON endpoints
gem "rswag-api"
# A Rails Engine that includes swagger-ui and powers it from configured OpenAPI (formerly named Swagger) endpoints
gem "rswag-ui"
# TODO: Retirer quand ce fix est mergé : https://github.com/rswag/rswag/pull/790
gem "ostruct"

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
gem "dsfr-assets", "~> 1.14.2"
gem "dsfr-view-components", "~> 4.1"
gem "dsfr-form_builder", "= 0.0.7" # On fixe la version tant qu’on est pas en 1.0

# Easily create styled HTML emails in Rails.
gem "premailer-rails" # Mail formatting
# The Spreadsheet Library is designed to read and write Spreadsheet Documents
gem "spreadsheet" # Excel export
# If string, numeric, symbol and nil values wanna be a boolean value, they can with the new #to_b method (and more).
gem "wannabe_bool" # imports to_b method

## Time Management

# Recurring events in Ruby
gem "montrose"
# Supplies TimeOfDay and Shift class
gem "tod"
# A ruby implementation of the iCalendar specification (RFC-5545).
gem "icalendar", "~> 2.5"
# Easy recurrence expansion for iCalendar
gem "icalendar-recurrence"
# ice_cube est utilisée par icalendar-recurrence pour calculer les occurrences des événements externes (Caldav)
# TODO: faire pointer vers rubygems quand ceci est released : https://github.com/ice-cube-ruby/ice_cube/pull/449
# Ruby Date Recurrence Library - Allows easy creation of recurrence rules and fast querying
gem "ice_cube", git: "https://github.com/ice-cube-ruby/ice_cube.git", ref: "32ff145"
# Caldav client library
gem "calendav", "~> 0.5"
# Base de données des fuseaux horaires
# Au lieu d’utiliser la base de données système qui peut différer entre les environnements (local, CI, production)
# on utilise cette gem pour avoir la même partout.
gem "tzinfo-data"

# Tame Rails' multi-line logging into a single line per request
gem "lograge"

# Utilisée pour les imports
gem "csv"

group :development do
  # Autoload dotenv in Rails in development (production, staging and demo envs already have env vars setup by the hosting provider)
  gem "dotenv-rails" # dotenv should always be loaded before rails

  #  Hot reload

  # Rails application preloader
  gem "spring", require: false
  # Listen to file modifications
  gem "listen" # Needed for ActiveSupport::EventedFileUpdateChecker. See config/environment/development.rb

  # Linters

  # Identify database issues before they hit production.
  gem "active_record_doctor"
  # Security vulnerability scanner for Ruby on Rails.
  gem "brakeman", require: false
  # Automatic Ruby code style checking tool.
  gem "rubocop", require: false
  # Code style checking for RSpec files
  gem "rubocop-rspec", require: false
  # Automatic Rails code style checking tool.
  gem "rubocop-rails", require: false
  # Slim template linting tool
  gem "slim_lint", require: false

  #  Debug

  # help to kill N+1 queries and unused eager loading.
  gem "bullet"
  # Better error page for Rails and other Rack apps
  gem "better_errors"
  # Retrieve the binding of a method's caller, or further up the stack.
  gem "binding_of_caller" # Enable the REPL in better_errors
  # A mini view framework for console/irb that's easy to use. Includes a no-wrap table, auto-pager, tree and menu.
  gem "hirb"
  # Profiles loading speed for rack applications.
  gem "rack-mini-profiler"
  # Used by rack-mini-profiler to display flamegraphs: trigger by adding "?pp=flamegraph" to your URL
  gem "stackprof"

  # Other

  # Manage Procfile-based applications
  gem "overmind", require: false
  # Gives letter_opener an interface for browsing sent emails
  gem "letter_opener_web" # Saves sent emails and serves them on /letter_opener
  # Entity-relationship diagram for your Rails models.
  gem "rails-erd", require: false # Keeps docs/domain_model.svg up-to-date. See .erdconfig
end

group :development, :test do
  gem "debug", require: "debug/prelude"
end

group :test do
  # Rspec

  # Run Test::Unit / RSpec / Cucumber / Spinach in parallel
  gem "parallel_tests"
  # RSpec for Rails
  gem "rspec-rails"
  # RSpec JUnit XML formatter
  gem "rspec_junit_formatter", require: false
  # Extracting `assigns` and `assert_template` from ActionDispatch.
  gem "rails-controller-testing"
  # An OpenAPI-based (formerly called Swagger) DSL for rspec-rails & accompanying rake task for generating OpenAPI specification files
  gem "rswag-specs"
  # rspec command for spring
  gem "spring-commands-rspec"
  # Time-resilient expectations in RSpec
  gem "rspec-wait"

  # Accessibility
  # aXe is now required as a JS package

  # Web browser simulation

  # Capybara aims to simplify the process of integration testing Rack applications, such as Rails, Sinatra or Merb
  gem "capybara"
  # Test your ActionMailer and Mailer messages in Capybara
  gem "capybara-email"
  # Automatically create snapshots when Cucumber steps fail with Capybara and Rails
  gem "capybara-screenshot", git: "https://github.com/mattheworiordan/capybara-screenshot.git", ref: "23a27be"
  # Playwright is an alternative to Selenium
  gem "capybara-playwright-driver"

  # Factories

  # factory_bot provides a framework and DSL for defining and using model instance factories.
  gem "factory_bot"
  # Easily generate fake data
  gem "faker"

  # Stubbing

  # Library for stubbing HTTP requests in Ruby.
  gem "webmock"
  # Record your test suite's HTTP interactions and replay them during future test runs for fast, deterministic, accurate tests.
  gem "vcr"

  # Modify your ENV
  gem "climate_control"

  gem "sinatra"
end
