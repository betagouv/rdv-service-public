describe AgentRole, type: :model do
  describe "#can_access_others_planning?" do
    subject { agent_role.can_access_others_planning? }
    context "admin level" do
      let(:agent_role) { build(:agent_role, :admin) }
      it { should be_truthy }
    end

    context "basic level, but agent is secretaire" do
      let(:agent) { build(:agent, :secretaire) }
      let(:agent_role) { build(:agent_role, agent: agent) }
      it { should be_truthy }
    end

    context "basic level" do
      let(:agent_role) { build(:agent_role, level: AgentRole::LEVEL_BASIC) }
      it { should be_falsy }
    end
  end
end
