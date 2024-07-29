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

    # On ne veut pas de notification si l'erreur 404 est causée par un lien à l'extérieur de l'application
    return if hint[:exception].is_a?(ActiveRecord::RecordNotFound) && !internal_referer

    # On ne veut pas de notification si l'agent vient de se connecter, car ça signifie probablement que le lien
    # n'était pas dans l'application (on ignore le cas d'un agent qui laisse une page ouverte et dont la session a expiré)
    host = event.request&.headers&.fetch("Host")
    if host
      agent_sign_in_url = Rails.application.routes.url_helpers.new_agent_session_url(host: host)
      redirected_from_sign_in = referer == agent_sign_in_url
      return if hint[:exception].is_a?(ActiveRecord::RecordNotFound) && redirected_from_sign_in
    end

    # prevent logging sensitive jobs arguments
    event.extra&.delete(:arguments) unless event.extra&.dig(:active_job)&.constantize&.log_arguments

    event
  rescue StandardError
    event.set_tags(error_in_before_send_callback: true)
    event
  end

  # Ces erreurs déclenchent un retry :
  # https://github.com/bensheldon/good_job?tab=readme-ov-file#how-concurrency-controls-work
  # Il ne nous est pas utile de les voir dans Sentry puisqu'elles ont un rôle de contrôle de flux.
  config.excluded_exceptions += ["GoodJob::ActiveJobExtensions::Concurrency::ConcurrencyExceededError"]
end

# # cf /config/initializers/sentry_job_retries_subscriber.rb for the log subscriber that sends warnings to Sentry
