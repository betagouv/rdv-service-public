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
end

def with_modified_env(options = {}, &block)
  ClimateControl.modify(options, &block)
end
