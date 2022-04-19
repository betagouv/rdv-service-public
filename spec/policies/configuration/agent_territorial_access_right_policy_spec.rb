# frozen_string_literal: true

describe Configuration::AgentTerritorialAccessRightPolicy, type: :policy do
  describe "#update?" do
    it "returns false with agent without admin access to this territory" do
      territory = create(:territory)
      agent = create(:agent, role_in_territories: [])
      agent_territorial_access_right = create(:agent_territorial_access_right, agent: agent, territory: territory)
      agent_territorial_context = AgentTerritorialContext.new(agent, territory)
      expect(described_class.new(agent_territorial_context, agent_territorial_access_right).update?).to be false
    end

    it "returns true with agent with admin access to this territory" do
      territory = create(:territory)
      agent = create(:agent, role_in_territories: [territory])
      agent_territorial_access_right = create(:agent_territorial_access_right, agent: agent, territory: territory)
      agent_territorial_context = AgentTerritorialContext.new(agent, territory)
      expect(described_class.new(agent_territorial_context, agent_territorial_access_right).update?).to be true
    end
  end
end
