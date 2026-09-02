RSpec.describe Agents::SessionsController do
  let(:agent) { create(:agent) }

  before do
    request.env["devise.mapping"] = Devise.mappings[:agent] # d'après la doc de Devise
  end

  describe "#create" do
    context "when the agent has a pro_connect_openid_sub" do
      let(:agent) { create(:agent, password: "c0rrecThorse!", pro_connect_openid_sub: "some-sub") }

      it "fails authentication and redirects to the login page with pro_connect_required param" do
        post :create, params: { agent: { email: agent.email, password: "c0rrecThorse!" } }

        expect(response).to redirect_to(new_agent_session_path(pro_connect_required: agent.email))
        expect(session["warden.agent.key"]).to be_nil
      end

      it "efface la session propre à l'agent (jetons ProConnect inclus)" do
        session[:agent] = { pro_connect_access_token: "fake_access_token", pro_connect_id_token: "fake_id_token" }
        post :create, params: { agent: { email: agent.email, password: "c0rrecThorse!" } }
        expect(session[:agent]).to be_nil
      end
    end

    context "when the agent does not have a pro_connect_openid_sub" do
      let(:agent) { create(:agent, password: "c0rrecThorse!") }

      it "signs in the agent normally" do
        post :create, params: { agent: { email: agent.email, password: "c0rrecThorse!" } }

        expect(controller.current_agent).to eq(agent)
      end
    end

    context "quand l'agent a un compte sensible" do
      let(:agent) { create(:agent, password: "c0rrecThorse!", sensitive_account: true) }

      it "ne connecte pas l'agent" do
        post :create, params: { agent: { email: agent.email, password: "c0rrecThorse!" } }
        expect(session["warden.agent.key"]).to be_nil
      end

      it "stocke l'id de l'agent dans la session comme connexion en attente" do
        post :create, params: { agent: { email: agent.email, password: "c0rrecThorse!" } }
        expect(session[Agents::SessionsByCodeController::SESSION_AGENT_ID_KEY]).to eq(agent.id)
      end

      it "redirige vers le formulaire de vérification par code" do
        post :create, params: { agent: { email: agent.email, password: "c0rrecThorse!" } }
        expect(response).to redirect_to(new_agents_sessions_by_code_path)
      end

      it "crée et envoie un code de connexion par email" do
        expect { post :create, params: { agent: { email: agent.email, password: "c0rrecThorse!" } } }
          .to change(LoginCode, :count).by(1)
          .and have_enqueued_mail(Agents::LoginCodeMailer, :login_code)
        expect(LoginCode.last.email).to eq(agent.email)
      end

      it "efface la session propre à l'agent (jetons ProConnect inclus)" do
        session[:agent] = { pro_connect_access_token: "fake_access_token", pro_connect_id_token: "fake_id_token" }
        post :create, params: { agent: { email: agent.email, password: "c0rrecThorse!" } }
        expect(session[:agent]).to be_nil
      end
    end
  end

  describe "#destroy" do
    before { sign_in agent }

    it "efface la session propre à l'agent (jetons ProConnect inclus)" do
      session[:agent] = { pro_connect_access_token: "fake_access_token" }
      get :destroy
      expect(session[:agent]).to be_nil
    end

    context "when the agent was logged in with ProConnect" do
      stub_env_with(PRO_CONNECT_BASE_URL: "https://fca.integ01.dev-agentconnect.fr/api/v2")

      before do
        ProConnectStubs.stub_and_run_discover_request
        # C'est compliqué de manipuler la session dans une feature spec, c'est pour ça qu'on utilise une spec de controller ici
        session[:agent] = { pro_connect_id_token: "fake_pro_connect_id_token" }
      end

      it "signs out the agent and redirects them to the ProConnect logout url with the right params" do
        get :destroy
        expect(session[:agent]).to be_nil

        redirect_url = response.headers["Location"]

        expect(redirect_url).to start_with("https://fca.integ01.dev-agentconnect.fr/api/v2/session/end")

        redirect_url_query_params = Rack::Utils.parse_query(URI.parse(redirect_url).query)

        expect(redirect_url_query_params.symbolize_keys).to match(
          id_token_hint: "fake_pro_connect_id_token",
          state: anything,
          post_logout_redirect_uri: "http://test.host/"
        )
      end
    end

    context "quand l'agent s'est connecté avec ProConnect avant la migration vers agent_session" do
      stub_env_with(PRO_CONNECT_BASE_URL: "https://fca.integ01.dev-agentconnect.fr/api/v2")

      before do
        ProConnectStubs.stub_and_run_discover_request
        # simule une session créée avant la migration vers agent_session, avec la clé plate uniquement
        session[:pro_connect_id_token] = "fake_pro_connect_id_token"
      end

      it "déconnecte l'agent et le redirige vers l'URL de déconnexion ProConnect en utilisant le jeton de fallback" do
        get :destroy

        redirect_url = response.headers["Location"]
        redirect_url_query_params = Rack::Utils.parse_query(URI.parse(redirect_url).query)

        expect(redirect_url_query_params["id_token_hint"]).to eq("fake_pro_connect_id_token")
      end
    end
  end
end
