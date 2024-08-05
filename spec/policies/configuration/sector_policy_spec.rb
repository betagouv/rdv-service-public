RSpec.describe Configuration::SectorPolicy, type: :policy do
  subject { described_class }

  context "agent does not have any territorial role" do
    let(:territory) { create(:territory) }
    let(:sector) { create(:sector, territory:) }
    let(:agent) { create(:agent) }
    let(:pundit_context) { AgentTerritorialContext.new(agent, territory) }

    it_behaves_like "not permit actions",
                    :sector,
                    :new?,
                    :create?,
                    :show?,
                    :edit?,
                    :update?,
                    :destroy?
  end

  context "agent has territorial role in sector territory" do
    let(:territory) { create(:territory) }
    let(:sector) { create(:sector, territory:) }
    let(:agent) { create(:agent, role_in_territories: [territory]) }
    let(:pundit_context) { AgentTerritorialContext.new(agent, territory) }

    it_behaves_like "permit actions",
                    :sector,
                    :new?,
                    :create?,
                    :show?,
                    :edit?,
                    :update?,
                    :destroy?
  end

  context "agent has territorial role in other territory" do
    let(:territory_sector) { create(:territory) }
    let(:territory_agent) { create(:territory) }
    let(:sector) { create(:sector, territory: territory_sector) }
    let(:agent) { create(:agent, role_in_territories: [territory_agent]) }

    context "context uses agent’s territory" do
      let(:pundit_context) { AgentTerritorialContext.new(agent, territory_agent) }

      it_behaves_like "not permit actions",
                      :sector,
                      :new?,
                      :create?,
                      :show?,
                      :edit?,
                      :update?,
                      :destroy?
    end

    context "context uses sector's territory" do
      let(:pundit_context) { AgentTerritorialContext.new(agent, territory_sector) }

      it_behaves_like "not permit actions",
                      :sector,
                      :new?,
                      :create?,
                      :show?,
                      :edit?,
                      :update?,
                      :destroy?
    end
  end
end
