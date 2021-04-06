describe Agent::AgentTerritorialRolePolicy, type: :policy do
  subject { described_class }

  let!(:territory) { create(:territory) }
  let(:pundit_context) { AgentContext.new(agent) }

  [:new?, :create?, :destroy?].each do |action|
    describe "##{action}" do
      let!(:agent) { create(:agent, role_in_territories: [territory]) }

      context "agent has role in territory" do
        let!(:agent_territorial_role) { build(:agent_territorial_role, agent: build(:agent), territory: territory) }

        permissions(action) { it { is_expected.to permit(pundit_context, agent_territorial_role) } }
      end

      context "agent does not have role in territory" do
        let!(:agent_territorial_role) { build(:agent_territorial_role, agent: build(:agent), territory: create(:territory)) }

        permissions(action) { it { is_expected.not_to permit(pundit_context, agent_territorial_role) } }
      end
    end
  end
end

describe Agent::AgentTerritorialRolePolicy::Scope, type: :policy do
  describe "#resolve?" do
    subject do
      described_class
        .new(AgentContext.new(agent), AgentTerritorialRole)
        .resolve
    end

    context "misc state" do
      let!(:territory1) { create(:territory) }
      let!(:territory2) { create(:territory) }
      let!(:territory3) { create(:territory) }
      let!(:agent) { create(:agent, role_in_territories: [territory1, territory2]) }
      let!(:role1) { create(:agent_territorial_role, agent: create(:agent), territory: territory1) }
      let!(:role1bis) { create(:agent_territorial_role, agent: create(:agent), territory: territory1) }
      let!(:role2) { create(:agent_territorial_role, agent: create(:agent), territory: territory2) }
      let!(:role3) { create(:agent_territorial_role, agent: create(:agent), territory: territory3) }

      it { is_expected.to include(role1) }
      it { is_expected.to include(role1bis) }
      it { is_expected.to include(role2) }
      it { is_expected.not_to include(role3) }
    end
  end
end
