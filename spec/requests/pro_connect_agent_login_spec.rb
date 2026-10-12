RSpec.describe "Connexion agent via ProConnect", type: :request do
  stub_env_for_proconnect

  let(:code) { "IDej8hpYou2rZLsDgTzZ_nMl1aXmNajpByd20dig4e8" }
  let(:user_info) do
    {
      "sub" => "ab70770d-1285-46e6-b4d0-3601b49698d4",
      "email" => "francis.factice@exemple.fr",
      "given_name" => "Francis Factice",
      "usual_name" => "Factice",
      "siret" => "13002526500013",
      "idp_id" => "fia1",
      "aud" => "4ec41582-1d60-4f12-a63b-d8abaace16ba",
      "exp" => 1717595030, "iat" => 1717594970, "iss" => "https://fca.integ01.dev-agentconnect.fr/api/v2",
    }
  end
  let!(:agent) { create(:agent, email: user_info["email"]) }

  before do
    ProConnectStubs.stub_callback_requests(code, user_info, host: "http://www.example.com")
  end

  it "lance la création des salons Visio avec le jeton d'accès ProConnect" do
    get pro_connect_auth_path(user_type: "agent")
    state = Rack::Utils.parse_query(URI.parse(response.headers["Location"]).query)["state"]

    expect { get pro_connect_callback_path(state:, code:) }
      .to have_enqueued_job(Agents::CreateVisioRoomsJob).with(agent, "fake proconnect access token")
  end
end
