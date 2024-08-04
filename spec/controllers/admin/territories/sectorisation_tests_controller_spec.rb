RSpec.describe Admin::Territories::SectorisationTestsController, type: :controller do
  let(:territory) { create(:territory, departement_number: "62") }
  let(:organisation) { create(:organisation, territory: territory) }
  let(:agent) { create(:agent, admin_role_in_organisations: [organisation], role_in_territories: [territory]) }

  before do
    sign_in agent
  end

  describe "#search" do
    context "without params" do
      it "returns success" do
        get :search, params: { territory_id: territory.id }
        expect(response).to be_successful
      end
    end

    context "with adresse parameters" do
      it "returns success" do
        get :search, params: {
          territory_id: territory.id,
          address: "21 Chemin de la Marion, Le Faouët, 5632, 56, Morbihan, Bretagne",
          departement: 56,
          city_code: 56_057,
          street_ban_id: 560_570_882,
          latitude: 48.039837,
          longitude: -3.498531,
          commit: "Tester la sectorisation de cette adresse",
        }
        expect(response).to be_successful
      end
    end
  end
end
