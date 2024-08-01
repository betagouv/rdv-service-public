RSpec.describe Agent::AgentRolePolicy::Scope, type: :policy do
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

      it do
        expect(subject).to include(own_agent_role_basic)
        expect(subject).to include(own_agent_role_admin1)
        expect(subject).to include(own_agent_role_admin2)

        expect(subject).not_to include(agent_role_basic_role)
        expect(subject).to include(agent_role_admin_role1)
        expect(subject).to include(agent_role_admin_role2)
        expect(subject).not_to include(agent_role_other_orga)
      end
    end
  end
end
