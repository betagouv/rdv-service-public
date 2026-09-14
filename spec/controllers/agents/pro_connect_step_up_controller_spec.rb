RSpec.describe Agents::ProConnectStepUpController do
  stub_env_for_proconnect

  describe "#new" do
    context "quand il n'y a pas de step-up en attente dans la session" do
      it "redirige vers la page de connexion" do
        get :new
        expect(response).to redirect_to(new_agent_session_path)
      end
    end

    context "quand il y a un step-up en attente dans la session" do
      before { session[described_class::SESSION_LOGIN_HINT_KEY] = "francis.factice@exemple.fr" }

      it "affiche la page de confirmation" do
        get :new
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "#create" do
    context "quand il n'y a pas de step-up en attente dans la session" do
      it "redirige vers la page de connexion" do
        post :create
        expect(response).to redirect_to(new_agent_session_path)
      end
    end

    context "quand il y a un step-up en attente dans la session" do
      before { session[described_class::SESSION_LOGIN_HINT_KEY] = "francis.factice@exemple.fr" }

      it "redirige vers ProConnect avec force_2fa" do
        post :create, params: { remember_device: "1" }

        expect(response).to redirect_to(start_with("https://fca.integ01.dev-agentconnect.fr/api/v2/authorize?"))

        redirect_url_query_params = Rack::Utils.parse_query(URI.parse(response.headers["Location"]).query)
        expect(redirect_url_query_params.symbolize_keys).to include(
          login_hint: "francis.factice@exemple.fr",
          claims: {
            id_token: {
              acr: {
                essential: true,
                values: %w[eidas0-mfa eidas1-mfa eidas2 eidas3],
              },
            },
          }.to_json
        )
      end

      it "met en place la session pro_connect pour la ré-authentification" do
        post :create, params: { remember_device: "1" }

        new_redirect_url = Rack::Utils.parse_query(URI.parse(response.headers["Location"]).query)
        expect(session["pro_connect"]).to include(connection_for: "agent",
                                                  state: new_redirect_url["state"],
                                                  nonce: new_redirect_url["nonce"])
      end

      it "mémorise le choix 'se souvenir de cet appareil' en session" do
        post :create, params: { remember_device: "1" }
        expect(session[described_class::SESSION_REMEMBER_DEVICE_KEY]).to be true
      end

      it "mémorise l'absence de choix quand la case n'est pas cochée" do
        post :create
        expect(session[described_class::SESSION_REMEMBER_DEVICE_KEY]).to be_falsey
      end
    end
  end
end
