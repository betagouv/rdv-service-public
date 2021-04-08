describe Agent::AgentRolePolicy, type: :policy do
  subject { described_class }

  let(:pundit_context) { AgentContext.new(agent) }
  let!(:organisation) { create(:organisation) }

  describe "#update?" do
    context "regular agent, own agent_role" do
      let!(:agent) { create(:agent) }
      let!(:agent_role) { create(:agent_role, level: AgentRole::LEVEL_BASIC, agent: agent, organisation: organisation) }

      permissions(:update?) { it { is_expected.not_to permit(pundit_context, agent_role) } }
    end

    context "admin agent, own agent_role" do
      let!(:agent) { create(:agent) }
      let!(:agent_role) { create(:agent_role, level: AgentRole::LEVEL_ADMIN, agent: agent, organisation: organisation) }

      permissions(:update?) { it { is_expected.to permit(pundit_context, agent_role) } }
    end

    context "admin agent, other agent's agent_role" do
      let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
      let!(:other_agent) { create(:agent) }
      let!(:agent_role) { create(:agent_role, level: AgentRole::LEVEL_ADMIN, agent: other_agent, organisation: organisation) }

      permissions(:update?) { it { is_expected.to permit(pundit_context, agent_role) } }
    end

    context "admin agent, other agent's agent_role in OTHER orga" do
      let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
      let!(:other_organisation) { create(:organisation) }
      let!(:other_agent) { create(:agent) }
      let!(:agent_role) { create(:agent_role, level: AgentRole::LEVEL_ADMIN, agent: other_agent, organisation: other_organisation) }

      permissions(:update?) { it { is_expected.not_to permit(pundit_context, agent_role) } }
    end
  end
end

describe Agent::AgentRolePolicy::Scope, type: :policy do
  describe "#resolve?" do
    subject { described_class.new(AgentContext.new(agent), AgentRole).resolve }

    context "misc state" do
      let!(:organisations) { create_list(:organisation, 4) }
      let!(:agent) { create(:agent) }
      let!(:own_agent_role_basic) { create(:agent_role, agent: agent, organisation: organisations[0]) }
      let!(:own_agent_role_admin1) { create(:agent_role, :admin, agent: agent, organisation: organisations[1]) }
      let!(:own_agent_role_admin2) { create(:agent_role, :admin, agent: agent, organisation: organisations[2]) }
      let!(:agent_role_basic_role) { create(:agent_role, agent: create(:agent), organisation: organisations[0]) }
      let!(:agent_role_admin_role1) { create(:agent_role, agent: create(:agent), organisation: organisations[1]) }
      let!(:agent_role_admin_role2) { create(:agent_role, agent: create(:agent), organisation: organisations[2]) }
      let!(:agent_role_other_orga) { create(:agent_role, agent: create(:agent), organisation: organisations[3]) }

      it { is_expected.to include(own_agent_role_basic) }
      it { is_expected.to include(own_agent_role_admin1) }
      it { is_expected.to include(own_agent_role_admin2) }

      it { is_expected.not_to include(agent_role_basic_role) }
      it { is_expected.to include(agent_role_admin_role1) }
      it { is_expected.to include(agent_role_admin_role2) }
      it { is_expected.not_to include(agent_role_other_orga) }
    end
  end
end
