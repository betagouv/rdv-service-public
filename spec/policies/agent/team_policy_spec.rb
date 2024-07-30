RSpec.describe Agent::TeamPolicy, type: :policy do
  %i[new? destroy? edit? update?].each do |action|
    describe "##{action}" do
      it "returns false with agent disllowed to manage teams" do
        access_right = create(:agent_territorial_access_right, allow_to_manage_teams: false)
        agent = access_right.agent
        territory = access_right.territory
        agent_territorial_context = AgentTerritorialContext.new(agent, territory)
        team = create(:team, territory: territory)
        expect(described_class.new(agent_territorial_context, team).send(action)).to be false
      end

      it "returns true with agent with admin access to this territory" do
        access_right = create(:agent_territorial_access_right, allow_to_manage_teams: true)
        agent = access_right.agent
        territory = access_right.territory
        agent_territorial_context = AgentTerritorialContext.new(agent, territory)
        team = create(:team, territory: territory)
        expect(described_class.new(agent_territorial_context, team).send(action)).to be true
      end

      it "returns false if team is from another territory" do
        access_right = create(:agent_territorial_access_right, allow_to_manage_teams: true)
        agent = access_right.agent
        territory = access_right.territory
        team = create(:team, territory: create(:territory))
        agent_territorial_context = AgentTerritorialContext.new(agent, territory)
        expect(described_class.new(agent_territorial_context, team).send(action)).to be false
      end
    end
  end

  %i[display? create?].each do |action|
    describe "##{action}" do
      it "returns false with agent disllowed to manage teams" do
        access_right = create(:agent_territorial_access_right, allow_to_manage_teams: false)
        agent = access_right.agent
        territory = access_right.territory
        agent_territorial_context = AgentTerritorialContext.new(agent, territory)
        team = create(:team, territory: territory)
        expect(described_class.new(agent_territorial_context, team).send(action)).to be false
      end

      it "returns true with agent with admin access to this territory" do
        access_right = create(:agent_territorial_access_right, allow_to_manage_teams: true)
        agent = access_right.agent
        territory = access_right.territory
        agent_territorial_context = AgentTerritorialContext.new(agent, territory)
        team = create(:team, territory: territory)
        expect(described_class.new(agent_territorial_context, team).send(action)).to be true
      end
    end
  end
end
