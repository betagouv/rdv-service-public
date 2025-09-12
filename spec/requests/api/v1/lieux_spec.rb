RSpec.describe "Lieux API" do
  let!(:oauth_token) { create(:access_token, resource_owner_id: agent.id, application:) }
  let(:headers) do
    { "Content-Type": "application/json", Authorization: "Bearer #{oauth_token.plaintext_token}" }
  end
  let(:application) { create(:oauth_application, default_service: create(:service)) }

  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

  describe "#create" do
    context "when a lieux already exists for the given external reference" do
      let(:params) do
        {
          organisation_id: organisation.id,
          latitude: 44.5569244,
          longitude: 4.7521632,
          name: "Maison France Service de Montreuil",
          address: "77 avenue de Ségur, 75015 Paris",
          phone_number: "01 22 33 44 55",
          external_reference: { external_id: "123ABC" },
        }
      end
      let!(:existing_lieu) do
        create(:lieu, organisation_id: organisation.id)
      end
      let!(:external_refenrece) do
        create(:external_reference, oauth_application: application, item: existing_lieu, territory_id: organisation.territory_id, external_id: "123ABC")
      end

      it "doesn't create the lieu and returns an error message" do
        expect { post "/api/v1/organisations", headers:, params:, as: :json }.not_to change(Lieu, :count)

        expect(response.status).to eq 422
        expect(response.error_message).to eq "asdf"
      end
    end
  end
end
