RSpec.describe Agent::AgentRolePolicy do
  subject { described_class }

  let(:territory) { create(:territory) }
  let(:organisation) { create(:organisation, territory: territory) }
  let(:agent_territorial_context) { AgentTerritorialContext.new(agent, territory) }

  shared_examples "permit actions" do |*actions|
    actions.each do |action|
      permissions action do
        it { is_expected.to permit(agent_territorial_context, agent_role) }
      end
    end
  end

  shared_examples "not permit actions" do |*actions|
    actions.each do |action|
      permissions action do
        it { is_expected.not_to permit(agent_territorial_context, agent_role) }
      end
    end
  end

  describe "agent with" do
    context "no admin access to this territory and no access rights" do
      let(:agent) { create(:agent, basic_role_in_organisations: [organisation], role_in_territories: []) }
      let!(:agent_role) { create(:agent_role, organisation: organisation) }

      it_behaves_like "not permit actions", :update?, :edit?, :create?, :destroy?
    end

    context "admin access to this territory" do
      let(:agent) { create(:agent, basic_role_in_organisations: [organisation], role_in_territories: [territory]) }
      let!(:agent_role) { create(:agent_role, organisation: organisation) }

      it_behaves_like "permit actions", :update?, :edit?, :create?, :destroy?
    end

    context "admin access to a different territory" do
      let(:agent) { create(:agent, basic_role_in_organisations: [organisation], role_in_territories: [territory]) }
      let!(:agent_role) { create(:agent_role, organisation: create(:organisation)) }

      it_behaves_like "not permit actions", :update?, :edit?, :create?, :destroy?
    end

    context "allowed to invite agents access right" do
      let(:agent) { create(:agent, basic_role_in_organisations: [organisation], role_in_territories: []) }
      let!(:agent_role) { create(:agent_role, organisation: organisation) }

      before do
        create(:agent_territorial_access_right, agent: agent, territory: organisation.territory, allow_to_invite_agents: true)
      end

      it_behaves_like "permit actions", :update?, :edit?, :create?, :destroy?
    end
  end
end

RSpec.describe Agent::AgentRolePolicy::Scope do
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
