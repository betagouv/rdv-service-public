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
    end

    context "when the agent does not have a pro_connect_openid_sub" do
      let(:agent) { create(:agent, password: "c0rrecThorse!") }

      it "signs in the agent normally" do
        post :create, params: { agent: { email: agent.email, password: "c0rrecThorse!" } }

        expect(controller.current_agent).to eq(agent)
      end
    end
  end

  describe "#destroy" do
    before { sign_in agent }

    context "when the agent was logged in with ProConnect" do
      stub_env_with(PRO_CONNECT_BASE_URL: "https://fca.integ01.dev-agentconnect.fr/api/v2")

      before do
        ProConnectStubs.stub_and_run_discover_request
        # C'est compliqué de manipuler la session dans une feature spec, c'est pour ça qu'on utilise une spec de controller ici
        session[:pro_connect_id_token] = "fake_pro_connect_id_token"
      end

      it "signs out the agent and redirects them to the ProConnect logout url with the right params" do
        get :destroy
        expect(session[:pro_connect_id_token]).to be_nil

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
  end
end
