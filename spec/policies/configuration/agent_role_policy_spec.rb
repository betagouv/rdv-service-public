# frozen_string_literal: true

describe Configuration::AgentRolePolicy, type: :policy do
  subject { described_class }

  let(:territory) { create(:territory) }
  let(:organisation) { create(:organisation, territory: territory) }
  let(:agent_territorial_context) { AgentTerritorialContext.new(agent, territory) }

  shared_examples "permit actions" do |*actions|
    actions.each do |action|
      permissions action do
        it { is_expected.to permit(agent_territorial_context, agent.role_in_organisation(organisation)) }
      end
    end
  end

  shared_examples "not permit actions" do |*actions|
    actions.each do |action|
      permissions action do
        it { is_expected.not_to permit(agent_territorial_context, agent.role_in_organisation(organisation)) }
      end
    end
  end

  describe "agent with" do
    context "no admin access to this territory and no access rights" do
      let(:agent) { create(:agent, basic_role_in_organisations: [organisation], role_in_territories: []) }
      let!(:access_rights) { create(:agent_territorial_access_right, agent: agent, territory: territory) }

      it_behaves_like "not permit actions", :update?, :edit?, :create?, :destroy?
    end

    context "admin access to this territory" do
      let(:agent) { create(:agent, basic_role_in_organisations: [organisation], role_in_territories: [territory]) }
      let!(:access_rights) { create(:agent_territorial_access_right, agent: agent, territory: territory) }

      it_behaves_like "permit actions", :update?, :edit?, :create?, :destroy?
    end

    context "allowed to invite agents access right" do
      let(:agent) { create(:agent, basic_role_in_organisations: [organisation], role_in_territories: []) }
      let!(:access_rights) { create(:agent_territorial_access_right, agent: agent, territory: territory, allow_to_invite_agents: true) }

      it_behaves_like "permit actions", :update?, :edit?, :create?, :destroy?
    end
  end
end
