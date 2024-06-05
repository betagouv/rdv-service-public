RSpec.describe AgentConnectController, type: :controller do
  before do
    stub_const("AgentConnectOpenIdClient::AGENT_CONNECT_CLIENT_SECRET", "un faux secret de test")
  end

  describe "#auth" do
    it "redirects to AgentConnect" do
      get :auth
      expect(response).to redirect_to(start_with("https://fca.integ01.dev-agentconnect.fr/api/v2/authorize?"))

      redirect_url = response.headers["Location"]
      redirect_url_query_params = Rack::Utils.parse_query(URI.parse(redirect_url).query)

      expect(redirect_url_query_params.symbolize_keys).to match(
        acr_values: "eidas1",
        client_id: AgentConnectOpenIdClient::AGENT_CONNECT_CLIENT_ID,
        redirect_uri: "http://test.host/agent_connect/callback",
        response_type: "code",
        scope: "openid email given_name usual_name",
        state: be_a_kind_of(String),
        nonce: be_a_kind_of(String)
      )
    end
  end

  describe "#callback" do
    let(:auth_client) { AgentConnectOpenIdClient::Auth.new }

    let(:state) { auth_client.state }

    let(:code) { "IDej8hpYou2rZLsDgTzZ_nMl1aXmNajpByd20dig4e8" }
    let(:userinfo_encoded_response_body) { "fake_userinfo_encoded_response_body" }
    let(:jwks_json) do
      File.read("#{::Rails.root}/spec/fixtures/agent_connect/jwks.json")
    end
    let(:jwks) { JSON.parse(jwks_json) }

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
      stub_token_request
      stub_userinfo_request(userinfo_encoded_response_body)

      stub_request(:get, "https://fca.integ01.dev-agentconnect.fr/api/v2/jwks").to_return(status: 200, body: jwks_json, headers: {})

      # En enregistrant puis en rejouant une vrai requête, on a une erreur  JWT::ExpiredSignature: Signature has expired
      # Le plus pragmatique pour cette spec semble donc d'être de stubber le JWT.decode
      allow(JWT).to receive(:decode).with(
        userinfo_encoded_response_body, nil, true,
        algorithms: "ES256",
        jwks: jwks["keys"]
      ).and_return([user_info])
    end

    it "works for the default case" do
      get :callback, params: { state: state, code: code }
    end
  end

  def stub_token_request
    stub_request(:post, "https://fca.integ01.dev-agentconnect.fr/api/v2/token").with(
      body: {
        "client_id" => AgentConnectOpenIdClient::AGENT_CONNECT_CLIENT_ID,
        "client_secret" => "un faux secret de test",
        "code" => code,
        "grant_type" => "authorization_code",
        "redirect_uri" => "http://test.host/agent_connect/callback",
      },
      headers: {
        "Content-Type" => "application/x-www-form-urlencoded",
      }
    ).to_return(status: 200, body: {
      id_token: "fake agent connect id token",
      access_token: "fake agent connect access token",
    }.to_json, headers: {})
  end

  def stub_userinfo_request(response_body)
    stub_request(:get, "https://fca.integ01.dev-agentconnect.fr/api/v2/userinfo?schema=openid")
      .with(
        headers: {
          "Authorization" => "Bearer fake agent connect access token",
          "Expect" => "",
          "User-Agent" => "Typhoeus - https://github.com/typhoeus/typhoeus",
        }
      )
      .to_return(status: 200, body: response_body, headers: {})
  end
end
