RSpec.describe FranceConnectV2Controller do
  stub_env_with(
    FRANCECONNECT_V2_BASE_URL: "https://fcp-low.sbx.dev-franceconnect.fr/api/v2",
    FRANCECONNECT_V2_CLIENT_ID: "fake_france_connect_v2_client_id",
    FRANCECONNECT_V2_CLIENT_SECRET: "fake_france_connect_v2_client_secret"
  )

  describe "#auth" do
    it "redirects to AgentConnect" do
      get :auth

      redirect_url = response.headers["Location"]
      expect(redirect_url).to start_with("https://fcp-low.sbx.dev-franceconnect.fr/api/v2/authorize?")
      redirect_url_query_params = Rack::Utils.parse_query(URI.parse(redirect_url).query)

      expect(redirect_url_query_params.symbolize_keys).to match(
        acr_values: "eidas1",
        client_id: "fake_france_connect_v2_client_id",
        # TODO: changer pour ""http://test.host/omniauth/franceconnect_v2/callback"" quand on a le bac à sable
        redirect_uri: "http://test.host/omniauth/franceconnect_v2/callback",
        response_type: "code",
        scope: "email openid birthdate given_name family_name",
        state: be_a(String),
        nonce: be_a(String)
      )
    end
  end

  describe "#callback" do
    let(:state) { auth_client.state }
    let(:auth_client) do
      FranceConnectV2OpenIdClient::Auth.new(
        client_id: "abcdef1234"
      )
    end
    let(:code) { "IDej8hpYou2rZLsDgTzZ_nMl1aXmNajpByd20dig4e8" }

    let(:user_info) do
      # Données enregistrées depuis l'env de bac à sable de FranceConnect V2
      {
        "email" => "wossewodda-3728@yopmail.com",
        "sub" => "88b65362bb23a04ba9031f244d12b9a45171fc6151c7a84c631170cd3da4b17bv1",
        "birthdate" => "1962-08-24",
        "given_name" => "Angela Claire Louise",
        "given_name_array" => %w[Angela Claire Louise],
        "family_name" => "DUBOIS",
        "aud" => "85783108e9a71edf25b7d5ab666c504a542da92400a1cdf6af5b57763cf55337",
        "exp" => 1748880813,
        "iat" => 1748880753,
        "iss" => "https://fcp-low.sbx.dev-franceconnect.fr/api/v2",
      }
    end

    before do
      session[FranceConnectV2Controller::STATE_SESSION_KEY] = state
      FranceConnectV2Stubs.stub_callback_requests(code, user_info)

      # session[:user_return_to] = "/users/informations" # Pour simuler le retour vers la page demandée avant la connexion
    end

    it "updates and logs in the user" do
      user = create(:user, email: "wossewodda-3728@yopmail.com")

      expect(UpsertUserForFranceconnectService).to receive(:new).with(have_attributes(sub: user_info["sub"])).and_call_original

      get :callback, params: { state: state, code: code }

      expect(user.reload).to have_attributes(
        logged_once_with_franceconnect: true,
        email: "wossewodda-3728@yopmail.com",
        first_name: "Angela Claire Louise",
        last_name: "DUBOIS",
        updated_at: be_within(10.seconds).of(Time.zone.now)
      )
      expect(session[:connected_with_franceconnect]).to be_present

      # expect(response).to redirect_to("/users/informations")
    end
  end
end
