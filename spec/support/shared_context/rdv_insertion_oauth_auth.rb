RSpec.shared_context "with rdv-insertion OAuth authentication" do
  stub_env_with(RDV_INSERTION_OAUTH_APPLICATION_UID: "rdv-insertion-app-uid")

  let(:oauth_token) do
    create(:access_token, resource_owner_id: agent.id, application: create(:oauth_application, uid: "rdv-insertion-app-uid"))
  end
  let(:auth_headers) { { Authorization: "Bearer #{oauth_token.plaintext_token}" } }
end
