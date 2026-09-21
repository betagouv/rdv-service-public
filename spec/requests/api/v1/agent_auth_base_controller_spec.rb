RSpec.describe Api::V1::AgentAuthBaseController do
  before do
    klass = Class.new(described_class) do
      def fake_action
        render plain: "ok"
      end
    end
    stub_const("Api::V1::TestController", klass)

    Rails.application.routes.disable_clear_and_finalize = true

    Rails.application.routes.draw do
      get "/api/v1/test/fake_action", to: "api/v1/test#fake_action"
    end
  end

  after { Rails.application.reload_routes! }

  let!(:oauth_token) { create(:access_token, resource_owner_id: agent.id) }
  let(:agent) { create(:agent) }

  describe "#detect_param_injection" do
    let!(:agent_org) { create(:agent_role).organisation }
    let!(:agent_territory) { create(:agent_territorial_access_right, agent:, territory: agent_org.territory).territory }

    it "returns a 403 when trying to access an org or territory outside the agent's scope" do
      # No ID, no blocking
      get "/api/v1/test/fake_action", headers: oauth_client_headers(oauth_token), as: :json
      expect(response).to have_http_status(:success)

      # ID of my org, no problem
      get "/api/v1/test/fake_action", headers: oauth_client_headers(oauth_token), params: { organisation_id: agent_org.id }, as: :json
      expect(response).to have_http_status(:success)

      # ID of an org that does not exist
      get "/api/v1/test/fake_action", headers: oauth_client_headers(oauth_token), params: { organisation_id: 12345789 }, as: :json
      expect(response).to have_http_status(:forbidden) # Important: does not reveal whether the org exists or not

      # ID of an org that exists but is outside the agent's scope
      get "/api/v1/test/fake_action", headers: oauth_client_headers(oauth_token), params: { organisation_id: create(:organisation).id }, as: :json
      expect(response).to have_http_status(:forbidden)

      # ID of my territory, no problem
      get "/api/v1/test/fake_action", headers: oauth_client_headers(oauth_token), params: { territory_id: agent_org.territory_id }, as: :json
      expect(response).to have_http_status(:success)

      # ID of a territory that does not exist
      get "/api/v1/test/fake_action", headers: oauth_client_headers(oauth_token), params: { territory_id: 12345789 }, as: :json
      expect(response).to have_http_status(:forbidden) # Important: does not reveal whether the territory exists or not

      # ID of a territory that exists but is outside the agent's scope
      get "/api/v1/test/fake_action", headers: oauth_client_headers(oauth_token), params: { territory_id: create(:territory).id }, as: :json
      expect(response).to have_http_status(:forbidden)

      # ID is injecting things
      get "/api/v1/test/fake_action", headers: oauth_client_headers(oauth_token), params: { territory_id: "; SELECT * FROM users" }, as: :json
      expect(response).to have_http_status(:success) # ignores bogus param
    end
  end
end
