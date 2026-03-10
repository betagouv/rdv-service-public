RSpec.describe FranceConnectV2Controller do
  stub_env_with(
    FRANCECONNECT_V2_BASE_URL: "https://fcp-low.sbx.dev-franceconnect.fr/api/v2",
    FRANCECONNECT_V2_CLIENT_ID: "fake_france_connect_v2_client_id",
    FRANCECONNECT_V2_CLIENT_SECRET: "fake_france_connect_v2_client_secret"
  )

  describe "#auth" do
    it "redirects to FranceConnect" do
      get :auth

      redirect_url = response.headers["Location"]
      expect(redirect_url).to start_with("https://fcp-low.sbx.dev-franceconnect.fr/api/v2/authorize?")
      redirect_url_query_params = Rack::Utils.parse_query(URI.parse(redirect_url).query)

      expect(redirect_url_query_params.symbolize_keys).to match(
        acr_values: "eidas1",
        client_id: "fake_france_connect_v2_client_id",
        redirect_uri: "http://test.host/franceconnect_v2/callback",
        response_type: "code",
        scope: "email openid birthdate given_name family_name preferred_username",
        state: be_a(String),
        nonce: be_a(String)
      )
    end
  end

  describe "#callback" do
    let(:state) { "une_valeur_random_de_state" }
    let(:code) { "une_valeur_random_de_code" }

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

      session[:user_return_to] = "/users/informations" # Pour simuler le retour vers la page demandée avant la connexion
    end

    it "updates and logs in the user" do
      user = create(:user, franceconnect_openid_sub: "88b65362bb23a04ba9031f244d12b9a45171fc6151c7a84c631170cd3da4b17bv1", email: nil)

      expect(UpsertUserForFranceconnectService).to receive(:new).with(have_attributes(user_info)).and_call_original

      get :callback, params: { state: state, code: code }

      expect(user.reload).to have_attributes(
        franceconnect_openid_sub: user_info["sub"],
        logged_once_with_franceconnect: true,
        notification_email: "wossewodda-3728@yopmail.com",
        email: nil,
        first_name: "Angela Claire Louise",
        last_name: "DUBOIS",
        updated_at: be_within(10.seconds).of(Time.zone.now)
      )
      expect(session[:france_connect_v2_id_token]).to eq("fake_france_connect_v2_id_token")

      expect(response).to redirect_to("/users/informations")
    end
  end

  describe "#post_logout" do
    it "redirects home" do
      session[:france_connect_v2_logout_state] = "une_valeur_random_de_state"
      get :post_logout, params: { state: "une_valeur_random_de_state" }
      expect(response).to redirect_to("/")
    end

    context "when state in session does not match with the return state" do
      it "redirects home and show a success message but warns Sentry" do
        session[:france_connect_v2_logout_state] = "une_valeur_random_de_state"
        get :post_logout, params: { state: "une_autre_valeur" }
        expect(response).to redirect_to("/")
        expect(sentry_events.last.message).to eq("State mismatch on FranceConnect logout")
        expect(sentry_events.last.extra).to eq({ session_state: "une_valeur_random_de_state", params_state: "une_autre_valeur" })
      end
    end
  end
end
