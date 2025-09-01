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
          post_logout_redirect_uri: "http://test.host/franceconnect_v2/post_logout"
        )
      end
    end

    context "when the agent was logged in with ProConnect" do
      stub_env_with(AGENT_CONNECT_BASE_URL: "https://fca.integ01.dev-agentconnect.fr/api/v2")

      before do
        AgentConnectStubs.stub_and_run_discover_request
        # C'est compliqué de manipuler la session dans une feature spec, c'est pour ça qu'on utilise une spec de controller ici
        session[:agent_connect_id_token] = "fake_agent_connect_id_token"
      end

      it "signs out the agent and redirects them to the ProConnect logout url with the right params" do
        get :destroy
        expect(session[:agent_connect_id_token]).to be_nil

        redirect_url = response.headers["Location"]

        expect(redirect_url).to start_with("https://fca.integ01.dev-agentconnect.fr/api/v2/session/end")

        redirect_url_query_params = Rack::Utils.parse_query(URI.parse(redirect_url).query)

        expect(redirect_url_query_params.symbolize_keys).to match(
          id_token_hint: "fake_agent_connect_id_token",
          state: anything,
          post_logout_redirect_uri: "http://test.host/"
        )
      end
    end
  end
end
