Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN_RAILS"]

  # Most 4xx errors are excluded by default.
  # See Sentry::Configuration::IGNORE_DEFAULT
  # and Sentry::Rails::IGNORE_DEFAULT
  # Cf https://docs.sentry.io/platforms/ruby/configuration/options/#optional-settings
  # config.excluded_exceptions += []

  # cf docs/5-role-de-vigie.md
  # et https://docs.sentry.io/platforms/ruby/guides/rails/configuration/filtering/
  config.excluded_exceptions -= ["ActiveRecord::RecordNotFound"]

  config.before_send = lambda do |event, hint|
    referer = event.request&.headers&.fetch("Referer", "")
    internal_referer = Domain::ALL.map(&:host_name).any? { referer&.include?(_1) }
    return if hint[:exception].is_a?(ActiveRecord::RecordNotFound) && !internal_referer

    # prevent logging sensitive jobs arguments
    event.extra&.delete(:arguments) unless event.extra&.dig(:active_job)&.constantize&.log_arguments

    event
  end

  # Ces erreurs déclenchent un retry :
  # https://github.com/bensheldon/good_job?tab=readme-ov-file#how-concurrency-controls-work
  # Il ne nous est pas utile de les voir dans Sentry puisqu'elles ont un rôle de contrôle de flux.
  config.excluded_exceptions += ["GoodJob::ActiveJobExtensions::Concurrency::ConcurrencyExceededError"]
end

# # cf /config/initializers/sentry_job_retries_subscriber.rb for the log subscriber that sends warnings to Sentry
