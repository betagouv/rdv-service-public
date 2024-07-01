Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN_RAILS"]

  # Most 4xx errors are excluded by default.
  # See Sentry::Configuration::IGNORE_DEFAULT
  # and Sentry::Rails::IGNORE_DEFAULT
  # Cf https://docs.sentry.io/platforms/ruby/configuration/options/#optional-settings
  # config.excluded_exceptions += []

  # Par défault, Sentry ignore les erreurs ActiveRecord::RecordNotFound pour éviter de faire remonter
  # des erreurs en cas de visite de page obsolètes
  # par exemple pour des ids non trouvés.
  # Dans le contexte des jobs, on a besoin de savoir s'il y a cette erreur
  # Par ailleurs, on préfère mettre une règle dans Sentry pour ignorer ces erreurs en dessous d'un
  # certain volume plutôt que de les rendre complètement invisibles.
  config.excluded_exceptions -= ["ActiveRecord::RecordNotFound"]

  # Ces erreurs déclenchent un retry :
  # https://github.com/bensheldon/good_job?tab=readme-ov-file#how-concurrency-controls-work
  # Il ne nous est pas utile de les voir dans Sentry puisqu'elles ont un rôle de contrôle de flux.
  config.excluded_exceptions += ["GoodJob::ActiveJobExtensions::Concurrency::ConcurrencyExceededError"]

  config.before_send = lambda do |event, hint|
    referer = event.request&.headers&.fetch("Referer", "")
    internal_referer = Domain::ALL.map(&:host_name).any? { referer&.include?(_1) }
    return if hint[:exception].is_a?(ActiveRecord::RecordNotFound) && !internal_referer

    event
  end
end
