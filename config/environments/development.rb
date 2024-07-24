require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing
  config.server_timing = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}",
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  config.hosts << ".ngrok.io"

  # Store uploaded files on the local file system (see config/storage.yml for options).
  # config.active_storage.service = :local

  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = { host: ENV["HOST"].sub(%r{^https?://}, "") }
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  if ENV["DEVELOPMENT_SMTP_USER_NAME"].present?
    config.action_mailer.smtp_settings = {
      user_name: ENV["DEVELOPMENT_SMTP_USER_NAME"],
      password: ENV["DEVELOPMENT_SMTP_PASWORD"],
      address: ENV["DEVELOPMENT_SMTP_HOST"],
      domain: ENV["DEVELOPMENT_SMTP_DOMAIN"],
      port: ENV["DEVELOPMENT_SMTP_PORT"],
      authentication: :cram_md5,
    }
  else
    config.action_mailer.delivery_method = :letter_opener_web
  end
  config.action_mailer.asset_host = ENV["HOST"]

  config.active_job.queue_adapter = :good_job
  # config.active_job.queue_adapter = :inline # perform all jobs inline

  config.action_mailer.perform_caching = false

  config.log_level = ENV.fetch("LOG_LEVEL", :info) # allows for individual config with ENV variable

  # allows to see debug logs when running with foreman / overmind
  # cf https://github.com/rails/sprockets-rails/issues/376#issuecomment-287560399
  logger = ActiveSupport::Logger.new($stdout)
  logger.formatter = config.log_formatter
  config.logger = ActiveSupport::TaggedLogging.new(logger)

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  config.action_view.annotate_rendered_view_with_filenames = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # Check N+1 Queries / Eager loading
  config.after_initialize do
    Bullet.enable = true
    # Bullet.alert = true
    Bullet.rails_logger = true
  end

  # https://github.com/JackC/tod/#activemodel-serializable-attribute-support
  config.active_record.time_zone_aware_types = [:datetime]
  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  # Ces domaines peuvent être utilisés en local sans modification du /etc/hosts.
  # En effet, Firefox et Chrome font pointer le TLD .localhost vers 127.0.0.1.
  config.hosts << "www.rdv-solidarites.localhost" # http://rdv-solidarites.localhost:3000/
  config.hosts << "www.rdv-aide-numerique.localhost" # http://rdv-aide-numerique.localhost:3000/
  config.hosts << "www.rdv-mairie.localhost" # http://rdv-mairie.localhost:3000/
end
