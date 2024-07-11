RSpec.describe Agents::SessionsController do
  let(:agent) { create(:agent) }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:agent] # rubocop:disable RSpec/InstanceVariable, c'est la doc de Devise qui dit de faire ça
    sign_in agent
  end

  describe "#destroy" do
    context "when the agent was logged in with Agent Connect" do
      stub_env_with(AGENT_CONNECT_BASE_URL: "https://fca.integ01.dev-agentconnect.fr/api/v2")

      before do
        AgentConnectStubs.stub_and_run_discover_request
        session[:agent_connect_id_token] = "fake_agent_connect_id_token"
      end

      it "signs out the agent and redirects them to the Agent Connect logout url with the right params" do
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
