RSpec.describe "On enregistre les appels à l'api pour mieux comprendre qui s'en sert et comment" do
  context "with OAuth authentication" do
    let!(:oauth_token) { create(:access_token, resource_owner_id: agent.id) }
    let(:organisation) { create(:organisation) }
    let(:agent) do
      create(:agent, basic_role_in_organisations: [organisation])
    end

    let(:user) { create(:user, organisations: [organisation]) }

    it "records the correct authentication type" do
      get "/api/v1/absences", headers: oauth_client_headers(oauth_token), as: :json
      expect(ApiCall.last.authentication_type).to eq "OAuth"
    end

    it "records the name of the params so that we can know which ones are used without saving personnal data" do
      post "/api/v1/users", headers: oauth_client_headers(oauth_token), params: { first_name: "Bob", organisation_ids: [organisation.id] }, as: :json

      expect(ApiCall.last.param_names).to eq %w[first_name organisation_ids]

      get "/api/v1/users", headers: oauth_client_headers(oauth_token), params: { ids: [123] }, as: :json

      expect(ApiCall.last.param_names).to eq ["ids"]
    end
  end
end
