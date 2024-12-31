Coverband.configure do |config|
  # L'interface web de Coverband nécessite un eval() en JS, ce que notre content_security_policy.rb interdit.
  # En activant cette config, on fait en sorte d'utiliser un CSP spécifique pour l'interface de Coverband
  # Voir : https://github.com/danmayer/coverband/pull/447
  config.csp_policy = true

  # default false. Experimental support for routes usage tracking.
  config.track_routes = true
end
