# frozen_string_literal: true

describe Team, type: :model do
  describe "validation" do
    it "invalid without name" do
      expect(build(:team, name: "")).to be_invalid
    end

    it "invalid with existing name" do
      create(:team, name: "ubberTeam")
      expect(build(:team, name: "ubberTeam")).to be_invalid
    end

    it "invalid when add agents from different territory" do
      territory = create(:territory)
      organisation = create(:organisation, territory: territory)
      agent = create(:agent, basic_role_in_organisations: [organisation])
      agent_from_other_territory = create(:agent, basic_role_in_organisations: [create(:organisation, territory: create(:territory))])

      expect(build(:team, territory: territory, agents: [agent, agent_from_other_territory])).to be_invalid
    end
  end

  describe "#to_s" do
    it "return Superteam" do
      agent = build(:team, name: "Superteam")
      expect(agent.to_s).to eq("Superteam")
    end
  end
end
