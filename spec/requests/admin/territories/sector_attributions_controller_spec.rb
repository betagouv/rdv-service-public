RSpec.describe Admin::Territories::SectorAttributionsController do
  let!(:territory) { territories(:default_territory) }
  let!(:organisation) { create(:organisation, territory:) }
  let!(:current_agent) { create(:agent, role_in_territories: [territory], admin_role_in_organisations: [organisation]) }
  let!(:sector) { create(:sector, territory:) }

  before { sign_in current_agent }

  describe "#create" do
    it "allows creating attribution at the organisation level" do
      params = {
        sector_attribution: {
          organisation_id: organisation.id,
          level: SectorAttribution::LEVEL_ORGANISATION,
        },
      }

      expect do
        post admin_territory_sector_attributions_path(territory_id: territory.id, sector_id: sector.id), params:
      end.to change(SectorAttribution, :count).by(1)
      expect(SectorAttribution.last).to have_attributes(params[:sector_attribution])
    end

    it "allows creating attribution at the agent level" do
      my_colleague = create(:agent, basic_role_in_organisations: [organisation])

      params = {
        sector_attribution: {
          organisation_id: organisation.id,
          agent_id: my_colleague.id,
          level: SectorAttribution::LEVEL_AGENT,
        },
      }

      expect do
        post admin_territory_sector_attributions_path(territory_id: territory.id, sector_id: sector.id), params:
      end.to change(SectorAttribution, :count).by(1)
      expect(SectorAttribution.last).to have_attributes(params[:sector_attribution])
    end

    context "when trying to link an arbitrary organisation" do
      it "raises an authorization error" do
        other_org = create(:organisation)

        params = {
          sector_attribution: {
            organisation_id: other_org.id,
            level: SectorAttribution::LEVEL_ORGANISATION,
          },
        }

        expect do
          post admin_territory_sector_attributions_path(territory_id: territory.id, sector_id: sector.id), params:
        end.not_to change(SectorAttribution, :count)
      end
    end

    context "when trying to link an arbitrary agent" do
      it "raises an authorization error" do
        other_agent = create(:agent)

        params = {
          sector_attribution: {
            organisation_id: organisation.id,
            agent_id: other_agent.id,
            level: SectorAttribution::LEVEL_AGENT,
          },
        }

        expect do
          post admin_territory_sector_attributions_path(territory_id: territory.id, sector_id: sector.id), params:
        end.not_to change(SectorAttribution, :count)
      end
    end
  end
end
