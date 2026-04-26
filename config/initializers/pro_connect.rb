# Le guide pour configurer ProConnect en local : docs/interconnexions/proconnect.md

require_relative "sentry"

module ProConnectDiscover
  CACHE_KEY = "pro_connect_discovery_config".freeze

  def self.cached = Rails.cache.fetch(CACHE_KEY) { discover! }
  def self.write_cache = Rails.cache.write(CACHE_KEY, discover!)
  def self.discover! = OpenIDConnect::Discovery::Provider::Config.discover!(ENV["PRO_CONNECT_BASE_URL"])
end

Rails.configuration.x.pro_connect_unreachable_at_boot_time = false

if ENV["PRO_CONNECT_BASE_URL"].present?
  begin
    Rails.configuration.x.pro_connect_config = ProConnectDiscover.cached
  rescue StandardError => e
    error_message = <<~MSG
      ProConnect n'est pas joignable au démarrage de l'application.
      Elle a été démarrée en désactivant le bouton ProConnect, mais elle aura besoin d'être redémarrée quand ProConnect sera à nouveau joignable."
    MSG

    Rails.logger.warn(error_message)
    Sentry.capture_exception(e, level: :warning)
    Sentry.capture_message(error_message)
    Rails.configuration.x.pro_connect_unreachable_at_boot_time = true
  end
end
