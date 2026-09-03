RSpec.describe "Api::Rdvinsertion authentication" do
  let!(:agent) { create(:agent, basic_role_in_organisations: [create(:organisation)]) }

  context "with OAuth authentication" do
    let!(:rdv_insertion_oauth_application) { create(:oauth_application, uid: "rdv-insertion-app-uid") }
    let!(:oauth_token) { create(:access_token, resource_owner_id: agent.id, application: rdv_insertion_oauth_application) }

    stub_env_with(RDV_INSERTION_OAUTH_APPLICATION_UID: "rdv-insertion-app-uid")

    it "authenticates the agent and records the correct authentication type" do
      post "/api/rdvinsertion/motif_categories", params: { name: "RSA Orientation", short_name: "rsa_orientation" },
                                                 headers: oauth_client_headers(oauth_token), as: :json

      expect(response).to have_http_status(:ok)
      expect(ApiCall.last.authentication_type).to eq "OAuth"
    end
  end

  context "with OAuth authentication from another application" do
    let!(:other_oauth_application) { create(:oauth_application, uid: "some-other-app-uid") }
    let!(:oauth_token) { create(:access_token, resource_owner_id: agent.id, application: other_oauth_application) }

    stub_env_with(RDV_INSERTION_OAUTH_APPLICATION_UID: "rdv-insertion-app-uid")

    it "returns unauthorized" do
      post "/api/rdvinsertion/motif_categories", params: { name: "RSA Orientation", short_name: "rsa_orientation" },
                                                 headers: oauth_client_headers(oauth_token), as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "with shared secret authentication" do
    let!(:shared_secret) { "S3cr3T" }
    let!(:auth_headers) { api_auth_headers_with_shared_secret(agent, shared_secret) }

    before do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("SHARED_SECRET_FOR_AGENTS_AUTH").and_return(shared_secret)
    end

    it "authenticates the agent and records the correct authentication type" do
      post "/api/rdvinsertion/motif_categories", params: { name: "RSA Orientation", short_name: "rsa_orientation" },
                                                 headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(ApiCall.last.authentication_type).to eq "SharedSecret"
    end
  end

  context "without authentication" do
    it "returns unauthorized" do
      post "/api/rdvinsertion/motif_categories", params: { name: "RSA Orientation", short_name: "rsa_orientation" }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
