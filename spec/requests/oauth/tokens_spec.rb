RSpec.describe "POST /oauth/token", type: :request do
  describe "grant_type=client_credentials" do
    let(:agent) { create(:agent) }
    let!(:application) { create(:oauth_application, grant_type: "client_credentials", agent:, redirect_uri: nil) }

    it "délivre un access_token sans resource_owner" do
      post "/oauth/token", params: { grant_type: "client_credentials", client_id: application.uid, client_secret: application.plaintext_secret }

      expect(response).to have_http_status(:success)
      access_token = response.parsed_body["access_token"]
      expect(access_token).to be_present
      token_record = Doorkeeper::AccessToken.by_token(access_token)
      expect(token_record.resource_owner_id).to be_nil
      expect(token_record.application).to eq(application)
    end

    it "refuse les credentials en Basic auth (uniquement en params body)" do
      post "/oauth/token", params: { grant_type: "client_credentials" }, headers: { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials(application.uid, application.plaintext_secret) }

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["error"]).to eq("invalid_client")
    end

    it "refuse un mauvais secret" do
      post "/oauth/token", params: { grant_type: "client_credentials", client_id: application.uid, client_secret: "mauvais" }

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["error"]).to eq("invalid_client")
    end
  end

  describe "restriction du grant à celui de l'application" do
    let(:agent) { create(:agent) }
    let!(:m2m_application) { create(:oauth_application, grant_type: "client_credentials", agent:, redirect_uri: nil) }
    let!(:web_application) { create(:oauth_application, grant_type: "authorization_code") }

    it "refuse client_credentials sur une application authorization_code" do
      post "/oauth/token", params: { grant_type: "client_credentials", client_id: web_application.uid, client_secret: web_application.plaintext_secret }

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["error"]).to eq("unauthorized_client")
    end

    it "refuse authorization_code sur une application client_credentials" do
      post "/oauth/token", params: { grant_type: "authorization_code", client_id: m2m_application.uid, client_secret: m2m_application.plaintext_secret, code: "whatever", redirect_uri: "https://example.com" }

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["error"]).to eq("unauthorized_client")
    end

    # le renouvellement par refresh_token (grant transverse) reste autorisé :
    # couvert par le parcours complet dans spec/features/agents/oauth_provider_spec.rb
  end
end
