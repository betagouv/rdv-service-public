# frozen_string_literal: true

describe Configuration::SectorPolicy, type: :policy do
  %i[display? edit? show? update?].each do |action|
    describe "##{action}" do
      it "returns false with agent without admin access to this territory" do
        territory = create(:territory)
        agent = create(:agent, role_in_territories: [])
        agent_territorial_context = AgentTerritorialContext.new(agent, territory)
        expect(described_class.new(agent_territorial_context, territory).send(action)).to be false
      end

      it "returns true with agent with admin access to this territory" do
        territory = create(:territory)
        agent = create(:agent, role_in_territories: [territory])
        agent_territorial_context = AgentTerritorialContext.new(agent, territory)
        expect(described_class.new(agent_territorial_context, territory).send(action)).to be true
      end
    end
  end
end
