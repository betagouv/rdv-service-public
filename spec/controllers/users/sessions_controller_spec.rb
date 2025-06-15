RSpec.describe Users::SessionsController do
  describe "#destroy" do
    before do
      request.env["devise.mapping"] = Devise.mappings[:user] # d'après la doc de Devise
      sign_in create(:user)
    end

    context "quand l'usager s'est connecté sans FranceConnect" do
      it "redirige vers la page d'accueil" do
        delete :destroy
        expect(response).to redirect_to("/")
      end
    end

    context "quand l'usager s'est connecté avec FranceConnect V1" do
      stub_env_with(FRANCECONNECT_HOST: "fcp.integ01.dev-franceconnect.fr")

      it "redirects to FranceConnect v1's /api/v1/logout" do
        session[:connected_with_franceconnect] = true

        delete :destroy

        expect(session[:connected_with_franceconnect]).to be_nil
        expect(response).to redirect_to("https://fcp.integ01.dev-franceconnect.fr/api/v1/logout")
      end
    end

    context "quand l'usager s'est connecté avec FranceConnect V2" do
      stub_env_with(
        FRANCECONNECT_V2_BASE_URL: "https://fcp-low.sbx.dev-franceconnect.fr/api/v2",
        FRANCECONNECT_V2_CLIENT_ID: "fake_france_connect_v2_client_id",
        FRANCECONNECT_V2_CLIENT_SECRET: "fake_france_connect_v2_client_secret"
      )

      before do
        FranceConnectV2Stubs.stub_and_run_discover_request
      end

      it "redirects to FranceConnect v2's /api/v2/session/end" do
        session[:france_connect_v2_id_token] = "token_de_logout"

        delete :destroy

        expect(session[:france_connect_v2_id_token]).to be_nil

        redirect_url = response.headers["Location"]
        expect(redirect_url).to start_with("https://fcp-low.sbx.dev-franceconnect.fr/api/v2/session/end?")

        redirect_url_query_params = Rack::Utils.parse_query(URI.parse(redirect_url).query)
        expect(redirect_url_query_params.symbolize_keys).to match(
          id_token_hint: "token_de_logout",
          state: session[:france_connect_v2_logout_state], # on passe à FC une valeur de state pour l'observer au retour de logout
          post_logout_redirect_uri: "http://test.host/omniauth/franceconnect_v2/post_logout"
        )
      end
    end
  end
end
