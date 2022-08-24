# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN_RAILS"]

  # Par défault, Sentry ignore les erreurs ActiveRecord::RecordNotFound pour éviter de faire remonter
  # des erreurs en cas de visite de page obsolètes
  # par exemple pour des ids non trouvés.
  # Dans le contexte des jobs, on a besoin de savoir s'il y a cette erreur
  # Par ailleurs, on préfère mettre une règle dans Sentry pour ignorer ces erreurs en dessous d'un
  # certain volume plutôt que de les rendre complètement invisibles.
  config.excluded_exceptions -= ['ActiveRecord::RecordNotFound']

  # Most 4xx errors are excluded by default.
  # See Sentry::Configuration::IGNORE_DEFAULT
  # and Sentry::Rails::IGNORE_DEFAULT
  # Cf https://docs.sentry.io/platforms/ruby/configuration/options/#optional-settings
  # config.excluded_exceptions += []
end
