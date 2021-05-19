# frozen_string_literal: true

RSpec.describe Admin::TerritoriesController, type: :controller do
  render_views

  let!(:territory) { create(:territory, departement_number: "62") }
  # let!(:organisation) { create(:organisation, territory: territory) }

  before { sign_in agent }

  describe "#update" do
    context "agent has role in territory" do
      let!(:territory) do
        create(
          :territory,
          name: "Yvelines",
          phone_number: "0101010101",
          departement_number: "78"
        )
      end
      let!(:agent) { create(:agent, role_in_territories: [territory]) }

      it "updates territory" do
        put(
          :update,
          params: {
            id: territory.id,
            territory: {
              name: "La Clé St Pierre",
              phone_number: "0202020202"
            }
          }
        )
        expect(response).to be_successful
        expect(territory.reload.name).to eq("La Clé St Pierre")
        expect(territory.reload.phone_number).to eq("0202020202")
      end
    end
  end
end
