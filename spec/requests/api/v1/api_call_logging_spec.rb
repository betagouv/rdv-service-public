RSpec.describe "On enregistre les appels à l'api pour mieux comprendre qui s'en sert et comment" do
  context "with OAuth authentication" do
    let!(:oauth_token) { create(:access_token, resource_owner_id: agent.id) }
    let(:agent) do
      create(:agent, basic_role_in_organisations: [create(:organisation)])
    end

    it "records the correct authentication type" do
      get "/api/v1/absences", headers: oauth_client_headers(oauth_token), as: :json
      expect(ApiCall.last.authentication_type).to eq "OAuth"
    end

    it "records the request's duration in ms" do
      get "/api/v1/absences", headers: oauth_client_headers(oauth_token), as: :json
      expect(ApiCall.last.duration_in_ms).to be_within(1000).of(50)
    end
  end
end
