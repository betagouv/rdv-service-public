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

  # send_default_pii est désactivé par défaut
  # L’activer envoie par défaut pour toutes les requêtes HTTP : les params, le body, les cookies, l’IP.
  # On retire les cookies et l’IP dont on n’a pas d’utilité directe dans le before_send ci-dessous.
  # Ça a été discuté et validé en termes de protection des données sensibles.
  # cf https://docs.sentry.io/platforms/ruby/guides/rack/migration/#removed-processors
  # cf https://github.com/betagouv/rdv-service-public/pull/5762
  config.send_default_pii = true

  config.before_send = lambda do |event, _hint|
    return event if !event.respond_to?(:exception) || !event.exception

    referer = event.request&.headers&.fetch("Referer", "")
    internal_referer = Domain::ALL.map(&:host_name).any? { referer&.include?(_1) }
    record_not_found = event.exception&.values&.map(&:type)&.include?("ActiveRecord::RecordNotFound")

    # On ne veut pas de notification si l'erreur 404 est causée par un lien à l'extérieur de l'application
    return if record_not_found && !internal_referer

    # On ne veut pas de notification si l'agent vient de se connecter, car ça signifie probablement que le lien
    # n'était pas dans l'application (on ignore le cas d'un agent qui laisse une page ouverte et dont la session a expiré)
    host = event.request&.headers&.fetch("Host")
    if host
      agent_sign_in_url = Rails.application.routes.url_helpers.new_agent_session_url(host: host)
      redirected_from_sign_in = referer == agent_sign_in_url
      return if record_not_found && redirected_from_sign_in
    end

    # on retire les cookies et l’IP qui viennent de send_default_pii mais qu’on ne veut pas conserver
    # les IP sont aussi filtrées côté serveur Sentry, c’est une protection supplémentaire ici
    Sentry::RequestInterface::IP_HEADERS.each { event.request&.headers&.delete(_1) }
    event.request&.cookies = []

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
