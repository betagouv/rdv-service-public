RSpec.describe Admin::Territories::SectorsController do
  let!(:territory) { create(:territory) }
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

  describe "#destroy" do
    it "works" do
      let!(:sector) { create(:sector, territory:) }

      expect do
        delete admin_territory_sector_path(territory_id: territory.id, id: sector.id)
      end.to change(Sector, :count).by(-1)
    end

    context "when passing an arbitrary sector ID" do
      let!(:external_sector) { create(:sector, territory: create(:territory)) }

      it "does not allow deletion" do
        expect do
          delete admin_territory_sector_path(territory_id: territory.id, id: external_sector.id)
        end.not_to change(Sector, :count)
      end
    end

    context "when passing an arbitrary sector ID using a POST request and the _method=delete param" do
      let!(:legit_sector) { create(:sector, territory:) }
      let!(:external_sector) { create(:sector, territory: create(:territory)) }

      it "deletes the sector whose ID is in the path" do
        params = {
          _method: "delete",
          sector: {
            id: external_sector.id,
          },
        }
        post admin_territory_sector_path(territory_id: territory.id, id: legit_sector.id), params: params
        expect { legit_sector.reload }.to(raise_error(ActiveRecord::RecordNotFound))
        expect { external_sector.reload }.not_to(raise_error(ActiveRecord::RecordNotFound))
      end
    end
  end
end
