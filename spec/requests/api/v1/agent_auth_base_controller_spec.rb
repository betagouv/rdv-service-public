RSpec.describe Api::V1::AgentAuthBaseController, type: :request do
  before do
    klass = Class.new(described_class) do
      def fake_action
        skip_authorization
        render plain: "current agent id is #{current_agent.id}"
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

  describe "authentication" do
    it "works" do
      get "/api/v1/test/fake_action", headers: oauth_client_headers(oauth_token), as: :json
      expect(response.body).to eq("current agent id is #{agent.id}")
    end

    it "returns a 401 (unauthorized) when the agent is soft deleted" do
      # AgentRemoval.new(agent, agent.organisations.sole).remove!
      agent.soft_delete
      expect(agent.deleted_at).to be_present
      get "/api/v1/test/fake_action", headers: oauth_client_headers(oauth_token), as: :json
      expect(response).to have_http_status(:unauthorized) # Important: does not reveal whether the org exists or not
    end
  end

  describe "clé d'API (préfixe rdvsp_pat_)" do
    let!(:api_token) { create(:api_token, agent:) }

    def get_with_api_token(token_value)
      get "/api/v1/test/fake_action", headers: { "Authorization" => "Bearer #{token_value}" }, as: :json
    end

    it "authentifie l'agent propriétaire de la clé" do
      get_with_api_token(api_token.raw_token)
      expect(response.body).to eq("current agent id is #{agent.id}")
    end

    it "met à jour last_used_at" do
      expect { get_with_api_token(api_token.raw_token) }.to change { api_token.reload.last_used_at }.from(nil)
    end

    it "retourne 401 si la clé est révoquée" do
      api_token.revoke!
      get_with_api_token(api_token.raw_token)
      expect(response).to have_http_status(:unauthorized)
    end

    it "retourne 401 si la clé est expirée" do
      api_token.update_column(:expires_at, 1.hour.ago) # rubocop:disable Rails/SkipsModelValidations
      get_with_api_token(api_token.raw_token)
      expect(response).to have_http_status(:unauthorized)
    end

    it "retourne 401 si la clé est inconnue" do
      get_with_api_token("rdvsp_pat_inconnu")
      expect(response).to have_http_status(:unauthorized)
    end

    it "ne confond pas avec un token OAuth (préfixe différent)" do
      get "/api/v1/test/fake_action", headers: { "Authorization" => "Bearer autrechose" }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

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

    it "reads organisation IDs in base 10 (like ActiveRecord), so a leading-zero value is not read as octal" do
      external_org = create(:organisation)

      # ActiveRecord casts a string id with String#to_i, which is base 10 ("010" => 10). Integer()
      # without an explicit base reads a leading zero as octal, so detect_param_injection could resolve
      # a different id than the one actually queried, and the check could be bypassed.
      get "/api/v1/test/fake_action", headers: oauth_client_headers(oauth_token), params: { organisation_id: "0#{external_org.id}" }, as: :json
      expect(response).to have_http_status(:forbidden)

      # A leading-zero id of my own org is still accepted (read in base 10, not corrupted by octal)
      get "/api/v1/test/fake_action", headers: oauth_client_headers(oauth_token), params: { organisation_id: "0#{agent_org.id}" }, as: :json
      expect(response).to have_http_status(:success)
    end
  end
end
