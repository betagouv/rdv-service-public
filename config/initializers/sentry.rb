# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN_RAILS"]

  # Par défault, Sentry ignore les erreurs ActiveRecord::RecordNotFound pour éviter de faire remonter
  # des erreurs en cas de visite de page obsolètes, par exemple pour des ids non trouvés.
  # Dans le contexte des jobs, et pour surveiller la présence de liens morts dans l'application,
  # on a besoin de savoir s'il y a cette erreur
  config.excluded_exceptions -= ['ActiveRecord::RecordNotFound']

  # Le block before_send permet de filtrer les events causés par des liens morts en dehors de l'app
  # Si on renvoie event, il sera envoyé à Sentry
  # Si on renvoie nil, rien ne sera envoyé à Sentry
  config.before_send = lambda do |event, hint|
    # On traite normalement les exceptions qui viennent d'un background job ou d'une tache rake
    return event unless event.request

    # On traite normalement les exceptions qui ne correspondent pas à un lien mort
    return event if hint[:exception].class.to_s != "ActiveRecord::RecordNotFound"

    referer = event.request.headers["Referer"]
    host = event.request.headers["Host"]

    if referer.include?(host)
      return event
    end

    nil
  end

  # Most 4xx errors are excluded by default.
  # See Sentry::Configuration::IGNORE_DEFAULT
  # and Sentry::Rails::IGNORE_DEFAULT
  # Cf https://docs.sentry.io/platforms/ruby/configuration/options/#optional-settings
  # config.excluded_exceptions += []
end
