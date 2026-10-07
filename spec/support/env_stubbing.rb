# See https://github.com/thoughtbot/climate_control?tab=readme-ov-file#usage

def stub_env_with(options)
  around do |example|
    with_modified_env(options) do
      example.run
    end
  end
end

def stub_env_for_proconnect
  stub_env_with(
    PRO_CONNECT_BASE_URL: "https://fca.integ01.dev-agentconnect.fr/api/v2",
    PRO_CONNECT_RDVSP_CLIENT_SECRET: "un faux secret de test",
    PRO_CONNECT_RDVSP_CLIENT_ID: "ec41582-1d60-4f11-a63b-d8abaece16aa"
  )

  # L'initializer config/initializers/pro_connect.rb fait un vrai appel réseau de découverte
  # OpenID au démarrage de l'application. On stubbe cet appel et on recharge l'initializer
  # pour chaque exemple, afin que le résultat ne dépende jamais de la disponibilité réelle
  # du serveur ProConnect de staging au moment du boot du process de test.
  before { ProConnectStubs.stub_and_run_discover_request }
end

def with_modified_env(options = {}, &block)
  ClimateControl.modify(options, &block)
end
