RSpec.describe Agent::AgentTerritorialRolePolicy do
  describe "#create_or_destroy?" do
    subject { described_class.new(current_agent, agent_territorial_role).create_or_destroy? }

    context "current_agent is territorial admin and target agent has a basic role in the same territory" do
      let(:territory) { create(:territory) }
      let(:current_agent) { create(:agent, role_in_territories: [territory]) }
      let(:organisation) { create(:organisation, territory:) }
      let(:other_agent) { create(:agent, basic_role_in_organisations: [organisation]) }
      let(:agent_territorial_role) { build(:agent_territorial_role, agent: other_agent, territory:) }

      it { is_expected.to be_truthy }
    end

    context "current_agent is not territorial admin and target agent has a basic role in the same territory" do
      let(:territory) { create(:territory) }
      let(:organisation) { create(:organisation, territory:) }
      let(:current_agent) { create(:agent, basic_role_in_organisations: [organisation]) }
      let(:other_agent) { create(:agent, basic_role_in_organisations: [organisation]) }
      let(:agent_territorial_role) { build(:agent_territorial_role, agent: other_agent, territory:) }

      it { is_expected.to be_falsey }
    end

    context "current_agent is territorial admin and target agent has a basic role in another territory" do
      let(:territory) { create(:territory) }
      let(:current_agent) { create(:agent, role_in_territories: [territory]) }
      let(:other_territory) { create(:territory) }
      let(:organisation) { create(:organisation, territory: other_territory) }
      let(:other_agent) { create(:agent, basic_role_in_organisations: [organisation]) }
      let(:agent_territorial_role) { build(:agent_territorial_role, agent: other_agent, territory:) }

      it { is_expected.to be_falsey }
    end
  end
end
