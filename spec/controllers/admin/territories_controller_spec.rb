# frozen_string_literal: true

RSpec.describe Admin::TerritoriesController, type: :controller do
  let(:territory) { create(:territory, departement_number: "62") }
  let(:organisation) { create(:organisation, territory: territory) }
  let(:agent) { create(:agent, role_in_territories: [territory], basic_role_in_organisations: [organisation]) }

  before { sign_in agent }

  describe "#update" do
    context "agent has role in territory" do
      it "returns success" do
        put :update, params: { id: territory.id, territory: { name: "La Clé St Pierre", phone_number: "0202020202" } }
        expect(response).to redirect_to edit_admin_territory_path(territory)
      end

      it "update territory" do
        expect do
          put :update, params: { id: territory.id, territory: { name: "La Clé St Pierre", phone_number: "0202020202" } }
        end.to change { territory.reload.name }.to("La Clé St Pierre")
      end
    end
  end
end
