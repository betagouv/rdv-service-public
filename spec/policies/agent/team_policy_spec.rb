RSpec.describe Agent::TeamPolicy do
  let(:team) { create(:team, territory: territory) }
  let(:territory) { create(:territory) }

  %i[create? new? destroy? edit? update? versions?].each do |action|
    describe "##{action}" do
      it "returns false with agent not allowed to manage teams" do
        access_right = create(:agent_territorial_access_right, territory: territory, allow_to_manage_teams: false)
        agent = access_right.agent
        team = create(:team, territory: territory)
        expect(described_class.new(agent, team).send(action)).to be_falsey
      end

      it "returns true with agent allowed to manage teams in this territory access to this territory" do
        access_right = create(:agent_territorial_access_right, territory: territory, allow_to_manage_teams: true)
        agent = access_right.agent
        expect(described_class.new(agent, team).send(action)).to be true
      end

      context "when team is from another territory" do
        let(:team) { create(:team, territory: create(:territory)) }

        it "returns false" do
          access_right = create(:agent_territorial_access_right, territory: territory, allow_to_manage_teams: true)
          agent = access_right.agent
          expect(described_class.new(agent, team).send(action)).to be_falsey
        end
      end
    end
  end

  describe ".allowed_to_manage_teams_in?" do
    it "returns false with agent not allowed to manage teams" do
      access_right = create(:agent_territorial_access_right, allow_to_manage_teams: false)
      agent = access_right.agent
      territory = access_right.territory
      expect(described_class.allowed_to_manage_teams_in?(territory, agent)).to be false
    end

    it "returns true with agent with agent allowed to manage teams to this territory" do
      access_right = create(:agent_territorial_access_right, allow_to_manage_teams: true)
      agent = access_right.agent
      territory = access_right.territory
      expect(described_class.allowed_to_manage_teams_in?(territory, agent)).to be true
    end
  end
end
