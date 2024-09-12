RSpec.describe AgentConnectController do
  stub_env_with(
    AGENT_CONNECT_BASE_URL: "https://fca.integ01.dev-agentconnect.fr/api/v2",
    AGENT_CONNECT_RDVS_CLIENT_SECRET: "un faux secret de test",
    AGENT_CONNECT_RDVS_CLIENT_ID: "ec41582-1d60-4f11-a63b-d8abaece16aa"
  )

  describe "#auth" do
    it "redirects to AgentConnect" do
      get :auth
      expect(response).to redirect_to(start_with("https://fca.integ01.dev-agentconnect.fr/api/v2/authorize?"))

      redirect_url = response.headers["Location"]
      redirect_url_query_params = Rack::Utils.parse_query(URI.parse(redirect_url).query)

      expect(redirect_url_query_params.symbolize_keys).to match(
        acr_values: "eidas1",
        client_id: "ec41582-1d60-4f11-a63b-d8abaece16aa",
        redirect_uri: "http://test.host/agent_connect/callback",
        response_type: "code",
        scope: "openid email given_name usual_name",
        state: be_a(String),
        nonce: be_a(String)
      )
    end
  end

  describe "#callback" do
    let(:state) { auth_client.state }
    let(:auth_client) do
      AgentConnectOpenIdClient::Auth.new(
        client_id: "ec41582-1d60-4f11-a63b-d8abaece16aa",
        client_secret: "un faux secret de test"
      )
    end
    let(:code) { "IDej8hpYou2rZLsDgTzZ_nMl1aXmNajpByd20dig4e8" }

    let(:user_info) do
      {
        "sub" => "ab70770d-1285-46e6-b4d0-3601b49698d4",
        "email" => "francis.factice@exemple.gouv.fr",
        "given_name" => "Francis Factice",
        "usual_name" => "Factice",
        "aud" => "4ec41582-1d60-4f12-a63b-d8abaace16ba",
        "exp" => 1717595030, "iat" => 1717594970, "iss" => "https://fca.integ01.dev-agentconnect.fr/api/v2",
      }
    end

    before do
      session[:agent_connect_state] = state
      AgentConnectStubs.stub_callback_requests(code, user_info)
    end

    it "updates and logs in the agent" do
      agent = create(:agent, email: "francis.factice@exemple.gouv.fr")
      get :callback, params: { state: state, code: code }

      expect(agent.reload).to have_attributes(
        connected_with_agent_connect: true,
        first_name: "Francis",
        last_name: "Factice",
        last_sign_in_at: be_within(10.seconds).of(Time.zone.now)
      )
      expect(session["agent_connect_id_token"]).to be_present
    end

    context "when the agent has a name with two words" do
      let(:user_info) do
        {
          "sub" => "ab70770d-1285-46e6-b4d0-3601b49698d4",
          "email" => "jean.michel.factice@exemple.gouv.fr",
          "given_name" => "Jean Michel Factice",
          "usual_name" => "Factice",
          "aud" => "4ec41582-1d60-4f12-a63b-d8abaace16ba",
          "exp" => 1717595030, "iat" => 1717594970, "iss" => "https://fca.integ01.dev-agentconnect.fr/api/v2",
        }
      end

      it "sets the proper first and last name for the agent" do
        agent = create(:agent, email: "jean.michel.factice@exemple.gouv.fr")
        get :callback, params: { state: state, code: code }

        expect(agent.reload).to have_attributes(
          first_name: "Jean Michel",
          last_name: "Factice"
        )
      end
    end
  end
end
