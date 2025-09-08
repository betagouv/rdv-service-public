RSpec.describe "RDV API" do
  let!(:oauth_token) do
    create(:access_token, resource_owner_id: agent.id, application:)
  end
  let(:headers) do
    {
      "Content-Type": "application/json",
      Authorization: "Bearer #{oauth_token.plaintext_token}",
    }
  end
  let(:application) { create(:oauth_application, default_service: create(:service)) }
  let(:agent) { create(:agent) }

  describe "#create" do
    it "allows creating an organisation according to the policy rules" do
      post "/api/v1/organisations", headers: headers, params: { organisation: { name: "CCAS de Montreuil" } }, as: :json
      expect(parsed_response_body["organisation"]["name"]).to eq "CCAS de Montreuil"
      expect(agent.reload.organisations.first).to have_attributes(name: "CCAS de Montreuil")
    end
  end
end
