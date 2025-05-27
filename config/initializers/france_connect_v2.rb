require_relative "sentry"

Rails.configuration.x.france_connect_v2_unreachable_at_boot_time = false

if ENV["FRANCECONNECT_V2_BASE_URL"].present?
  begin
    # la méthode .discover! fait un appel à l'api d'Agent Connect
    Rails.configuration.x.france_connect_v2_config = OpenIDConnect::Discovery::Provider::Config.discover!(ENV["FRANCECONNECT_V2_BASE_URL"])
  rescue StandardError => e
    error_message = <<~MSG
      France Connect V2 n'est pas joignable au démarrage de l'application.
      Elle a été démarrée en désactivant le bouton France Connect V2, mais elle aura besoin d'être redémarrée quand France Connect sera à nouveau joignable."
    MSG

    Rails.logger.warn(error_message)
    Sentry.capture_exception(e, level: :warning)
    Sentry.capture_message(error_message)
    Rails.configuration.x.france_connect_v2_unreachable_at_boot_time = true
  end
end
