require_relative "sentry"

AGENT_CONNECT_UNREACHABLE_AT_BOOT_TIME = false

if ENV['AGENT_CONNECT_BASE_URL'].present? && !ENV['AGENT_CONNECT_DISABLED']
  begin
    # Cette ligne fait un appel à l'api d'Agent Connect
    AGENT_CONNECT_CONFIG = OpenIDConnect::Discovery::Provider::Config.discover!(ENV.fetch('AGENT_CONNECT_BASE_URL')) # TODO: mettre dans un objet Rails.configuration.x
  rescue StandardError => e
    Sentry.capture_exception(e)
    Sentry.capture_message <<~MSG
      Agent Connect n'est pas joignable au démarrage de l'application.
      Elle a été démarrée en désactivant le bouton Agent Connect, mais elle aura besoin d'être redémarrée quand Agent Connect sera à nouveau joignable."
    MSG
    AGENT_CONNECT_UNREACHABLE_AT_BOOT_TIME = true
  end
end
