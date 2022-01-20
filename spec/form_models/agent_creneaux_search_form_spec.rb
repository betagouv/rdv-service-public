# frozen_string_literal: true

describe AgentCreneauxSearchForm, type: :form do
  describe "#agent_ids" do
    it "return empty array without agent or teams" do
      form = described_class.new
      expect(form.agent_ids).to be_empty
    end

    it "return [1] with one agent given" do
      agent = create(:agent)
      form = described_class.new(agent_ids: [agent.id])
      expect(form.agent_ids).to contain_exactly(agent.id)
    end

    it "return [1, 2] with team given" do
      organisation = create(:organisation)
      agent = create(:agent, basic_role_in_organisations: [organisation])
      other_agent = create(:agent, basic_role_in_organisations: [organisation])
      team = create(:team, agents: [agent, other_agent])
      form = described_class.new(team_ids: [team.id])
      expect(form.agent_ids).to contain_exactly(agent.id, other_agent.id)
    end

    it "return [1, 2, 3] with team and agent given" do
      organisation = create(:organisation)
      agent = create(:agent, basic_role_in_organisations: [organisation])
      other_agent = create(:agent, basic_role_in_organisations: [organisation])
      agent_alone = create(:agent, basic_role_in_organisations: [organisation])
      team = create(:team, agents: [agent, other_agent])
      form = described_class.new(team_ids: [team.id], agent_ids: [agent_alone.id])
      expect(form.agent_ids).to contain_exactly(agent.id, other_agent.id, agent_alone.id)
    end
  end
end
