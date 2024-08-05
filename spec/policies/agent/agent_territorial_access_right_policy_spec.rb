RSpec.describe Agent::AgentTerritorialAccessRightPolicy do
  let(:territory) { create(:territory) }
  let(:agent_territorial_access_right) { create(:agent_territorial_access_right, territory: territory) }

  describe "#update?" do
    it "returns false with agent without admin access to this territory" do
      agent = create(:agent, role_in_territories: [])
      expect(described_class.new(agent, agent_territorial_access_right).update?).to be false
    end

    it "returns true with agent with admin access to this territory" do
      agent = create(:agent, role_in_territories: [territory])
      expect(described_class.new(agent, agent_territorial_access_right).update?).to be true
    end

    it "returns true with agent with access rights for access rights" do
    end
  end
end
