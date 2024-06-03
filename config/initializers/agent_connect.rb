if ENV['AGENT_CONNECT_BASE_URL'].present? && !ENV['DISABLE_AGENT_CONNECT']
  AgentConnectOpenIdClient::AGENT_CONNECT_CONFIG = OpenIDConnect::Discovery::Provider::Config.discover!(ENV.fetch('AGENT_CONNECT_BASE_URL'))
end
