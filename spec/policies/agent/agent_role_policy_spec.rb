RSpec.describe Agent::AgentRolePolicy do
  subject { described_class }

  let(:territory) { create(:territory) }
  let(:organisation) { create(:organisation, territory: territory) }

  shared_examples "permit actions" do |*actions|
    actions.each do |action|
      permissions action do
        it { is_expected.to permit(agent, agent_role) }
      end
    end
  end

  shared_examples "not permit actions" do |*actions|
    actions.each do |action|
      permissions action do
        it { is_expected.not_to permit(agent, agent_role) }
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

    context "allowed to invite agents access right in a different territory" do
      let(:agent) { create(:agent, basic_role_in_organisations: [organisation], role_in_territories: []) }
      let!(:agent_role) { create(:agent_role, organisation: organisation) }

      before do
        create(:agent_territorial_access_right, agent: agent, territory: create(:territory), allow_to_invite_agents: true)
      end

      it_behaves_like "not permit actions", :update?, :edit?, :create?, :destroy?
    end
  end
end
