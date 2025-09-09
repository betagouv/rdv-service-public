RSpec.describe "RDV API" do
  let!(:oauth_token) { create(:access_token, resource_owner_id: agent.id, application:) }
  let(:headers) do
    { "Content-Type": "application/json", Authorization: "Bearer #{oauth_token.plaintext_token}" }
  end
  let(:application) { create(:oauth_application, default_service: create(:service)) }
  let(:agent) { create(:agent) }

  describe "#create" do
    let(:params) do
      {
        name: "CCAS de Montreuil",
        external_reference: {
          external_id: 123,
        },
      }
    end

    it "allows creating an organisation according to the policy rules" do
      post "/api/v1/organisations", headers:, params:, as: :json
      expect(parsed_response_body["organisation"]["name"]).to eq "CCAS de Montreuil"

      created_organisation = agent.reload.organisations.first
      expect(created_organisation).to have_attributes(name: "CCAS de Montreuil")

      expect(created_organisation.external_references.first).to have_attributes(
        oauth_application_id: application.id,
        territory: created_organisation.territory,
        external_id: "123"
      )
    end
  end
end
