if ENV['AGENT_CONNECT_BASE_URL'].present?
  AGENT_CONNECT_CONFIG = OpenIDConnect::Discovery::Provider::Config.discover!(ENV.fetch('AGENT_CONNECT_BASE_URL'))
end
