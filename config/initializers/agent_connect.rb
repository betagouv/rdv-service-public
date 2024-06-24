require_relative "sentry"

Rails.configuration.x.agent_connect_unreachable_at_boot_time = false

if ENV['AGENT_CONNECT_BASE_URL'].present? && !ENV['AGENT_CONNECT_DISABLED']
  begin
    # la méthode .discover! fait un appel à l'api d'Agent Connect
    Rails.configuration.x.agent_connect_config = OpenIDConnect::Discovery::Provider::Config.discover!(ENV['AGENT_CONNECT_BASE_URL'])
  rescue StandardError => e
    Sentry.capture_exception(e)
    Sentry.capture_message <<~MSG
      Agent Connect n'est pas joignable au démarrage de l'application.
      Elle a été démarrée en désactivant le bouton Agent Connect, mais elle aura besoin d'être redémarrée quand Agent Connect sera à nouveau joignable."
    MSG
    Rails.configuration.x.agent_connect_unreachable_at_boot_time = true
  end
end
