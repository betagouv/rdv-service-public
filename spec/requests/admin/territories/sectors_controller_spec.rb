RSpec.describe Admin::Territories::SectorsController do
  let!(:territory) { territories(:default_territory) }
  let!(:current_agent) { create(:agent, role_in_territories: [territory]) }

  before { sign_in current_agent }

  describe "#update" do
    let!(:sector) { create(:sector, territory:) }

    it "allows updating name and human_id" do
      params = {
        sector: {
          name: "New name",
          human_id: "new_human_id",
        },
      }

      expect do
        patch admin_territory_sector_path(territory_id: territory.id, id: sector.id), params:
      end.to change { sector.reload.attributes }
      expect(Sector.last).to have_attributes(params[:sector])
    end

    context "when trying to update territory to an arbitrary one" do
      it "raises an authorization error" do
        other_territory = create(:territory)

        params = {
          sector: {
            territory_id: other_territory.id,
          },
        }

        expect do
          patch admin_territory_sector_path(territory_id: territory.id, id: sector.id), params:
        end.not_to change { sector.reload.attributes }
      end
    end
  end
end
