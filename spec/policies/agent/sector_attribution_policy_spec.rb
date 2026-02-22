RSpec.describe Agent::SectorAttributionPolicy do
  subject { described_class }

  let(:pundit_context) { agent }

  context "agent does not have any territorial role" do
    let(:territory) { territories(:default_territory) }
    let(:sector) { create(:sector, territory:) }
    let(:sector_attribution) { create(:sector_attribution, sector:) }
    let(:agent) { create(:agent) }

    it_behaves_like "not permit actions",
                    :sector_attribution,
                    :new?,
                    :create?,
                    :destroy?
  end

  context "agent has territorial role in sector_attribution territory" do
    let(:territory) { territories(:default_territory) }
    let(:sector) { create(:sector, territory:) }
    let(:sector_attribution) { create(:sector_attribution, sector:) }
    let(:agent) { create(:agent, role_in_territories: [territory]) }

    it_behaves_like "permit actions", :sector_attribution,
                    :new?,
                    :create?,
                    :destroy?
  end

  context "agent has territorial role in other territory" do
    let(:territory_sector_attribution) { create(:territory) }
    let(:territory_agent) { create(:territory) }
    let(:sector) { create(:sector, territory: territory_sector_attribution) }
    let(:sector_attribution) { create(:sector_attribution, sector:) }
    let(:agent) { create(:agent, role_in_territories: [territory_agent]) }

    it_behaves_like "not permit actions", :sector_attribution,
                    :new?,
                    :create?,
                    :destroy?
  end

  context "organisation is not in the territory" do
    let(:territory) { territories(:default_territory) }
    let(:sector) { create(:sector, territory: territory) }
    let(:sector_attribution) { build(:sector_attribution, sector:, organisation: create(:organisation)) }
    let(:agent) { create(:agent, role_in_territories: [territory]) }

    it_behaves_like "not permit actions", :sector_attribution,
                    :create?,
                    :destroy?
  end

  context "agent is not in the territory" do
    let(:territory) { territories(:default_territory) }
    let(:sector) { create(:sector, territory: territory) }
    let(:sector_attribution) { build(:sector_attribution, :level_agent, sector:, agent: create(:agent)) }
    let(:agent) { create(:agent, role_in_territories: [territory]) }

    it_behaves_like "not permit actions", :sector_attribution,
                    :create?,
                    :destroy?
  end
end
