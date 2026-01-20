# Le guide pour configurer ProConnect en local : docs/interconnexions/proconnect.md

module ProConnect
  DISCOVERY_CACHE_KEY = "pro_connect_discovery_config".freeze

  def self.base_url
    ENV["PRO_CONNECT_BASE_URL"].presence
  end

  def self.display_button?(domain)
    base_url && !disabled? && client_id(domain)
  end

  def self.disabled?
    ENV["PRO_CONNECT_DISABLED"].present?
  end

  def self.client_id(domain)
    {
      Domain::RDV_SOLIDARITES => ENV["PRO_CONNECT_RDVS_CLIENT_ID"],
      Domain::RDV_AIDE_NUMERIQUE => ENV["PRO_CONNECT_RDVAN_CLIENT_ID"],
      Domain::RDV_SERVICE_PUBLIC => ENV["PRO_CONNECT_RDVSP_CLIENT_ID"],
    }.fetch(domain).presence or raise "ProConnect client id not found for #{domain.id}"
  end

  def self.open_id_config_discover!
    OpenIDConnect::Discovery::Provider::Config.discover!(base_url)
  end
end

if ProConnect.base_url
  Rails.configuration.x.pro_connect_config = Rails.cache.fetch(ProConnect::DISCOVERY_CACHE_KEY, expires_in: 2.weeks) do
    ProConnect.open_id_config_discover!
  end
end
