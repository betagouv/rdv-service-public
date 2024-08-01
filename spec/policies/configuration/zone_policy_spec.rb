RSpec.describe Configuration::ZonePolicy, type: :policy do
  subject { described_class }

  context "agent does not have any territorial role" do
    let(:territory) { create(:territory) }
    let(:sector) { create(:sector, territory:) }
    let(:zone) { create(:zone, sector:) }
    let(:agent) { create(:agent) }
    let(:pundit_context) { AgentTerritorialContext.new(agent, territory) }

    it_behaves_like "not permit actions",
                    :zone,
                    :new?,
                    :create?,
                    :destroy?
  end

  context "agent has territorial role in zone territory" do
    let(:territory) { create(:territory) }
    let(:sector) { create(:sector, territory:) }
    let(:zone) { create(:zone, sector:) }
    let(:agent) { create(:agent, role_in_territories: [territory]) }
    let(:pundit_context) { AgentTerritorialContext.new(agent, territory) }

    it_behaves_like "permit actions",
                    :zone,
                    :new?,
                    :create?,
                    :destroy?
  end

  context "agent has territorial role in other territory" do
    let(:territory_zone) { create(:territory) }
    let(:territory_agent) { create(:territory) }
    let(:sector) { create(:sector, territory: territory_zone) }
    let(:zone) { create(:zone, sector:) }
    let(:agent) { create(:agent, role_in_territories: [territory_agent]) }

    context "context uses agent’s territory" do
      let(:pundit_context) { AgentTerritorialContext.new(agent, territory_agent) }

      it_behaves_like "not permit actions",
                      :zone,
                      :new?,
                      :create?,
                      :destroy?
    end

    context "context uses zone's territory" do
      let(:pundit_context) { AgentTerritorialContext.new(agent, territory_zone) }

      it_behaves_like "not permit actions",
                      :zone,
                      :new?,
                      :create?,
                      :destroy?
    end
  end
end
