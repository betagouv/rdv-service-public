RSpec.describe Configuration::AgentTerritorialRolePolicy, type: :policy do
  %i[display? new? create? destroy?].each do |action|
    describe "##{action}" do
      it "returns false with agent without admin access to this territory" do
        territory = create(:territory)
        agent = create(:agent, role_in_territories: [])
        agent_territorial_context = AgentTerritorialContext.new(agent, territory)

        territorial_role = create(:agent_territorial_role, territory: territory)
        expect(described_class.new(agent_territorial_context, territorial_role).send(action)).to be false
      end

      it "returns false with agent with admin access to a different territory" do
        territory = create(:territory)
        agent = create(:agent, role_in_territories: [create(:territory)])
        agent_territorial_context = AgentTerritorialContext.new(agent, territory)

        territorial_role = create(:agent_territorial_role, territory: territory)
        expect(described_class.new(agent_territorial_context, territorial_role).send(action)).to be false
      end

      it "returns true with agent with admin access to this territory" do
        territory = create(:territory)
        agent = create(:agent, role_in_territories: [territory])
        agent_territorial_context = AgentTerritorialContext.new(agent, territory)

        territorial_role = create(:agent_territorial_role, territory: territory)
        expect(described_class.new(agent_territorial_context, territorial_role).send(action)).to be true
      end
    end
  end
end
