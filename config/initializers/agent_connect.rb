if ENV['AGENT_CONNECT_BASE_URL'].present? && !ENV['DISABLE_AGENT_CONNECT']
  # Cette ligne fait un appel à l'api d'Agent Connect
  AGENT_CONNECT_CONFIG = OpenIDConnect::Discovery::Provider::Config.discover!(ENV.fetch('AGENT_CONNECT_BASE_URL'))
  # TODO: mettre DISABLE_AGENT_CONNECT a true s'il y a une erreur lors de cet appel et notifier sentry
end
