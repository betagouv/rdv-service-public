RSpec.describe Configuration::AgentPolicy, type: :policy do
  subject { described_class }

  let(:territory) { create(:territory) }
  let(:pundit_context) { AgentTerritorialContext.new(agent, territory) }

  describe "agent with" do
    context "no admin access to this territory and no access_rights" do
      let(:agent) { create(:agent, role_in_territories: []) }
      let!(:access_rights) { create(:agent_territorial_access_right, agent: agent, territory: territory) }

      it_behaves_like "not permit actions", :agent, :display?, :edit?, :create?, :update_teams?
    end

    context "admin access to this territory" do
      let(:agent) { create(:agent, role_in_territories: [territory]) }
      let!(:access_rights) { create(:agent_territorial_access_right, agent: agent, territory: territory) }

      it_behaves_like "permit actions", :agent, :display?, :edit?, :create?, :update_teams?
    end

    context "allowed to manage teams agent" do
      let(:agent) { create(:agent, role_in_territories: []) }
      let!(:access_rights) { create(:agent_territorial_access_right, agent: agent, territory: territory, allow_to_manage_teams: true) }

      it_behaves_like "permit actions", :agent, :display?, :edit?, :update_teams?
    end

    context "allowed to invite agents agent" do
      let(:agent) { create(:agent, role_in_territories: []) }
      let!(:access_rights) { create(:agent_territorial_access_right, agent: agent, territory: territory, allow_to_invite_agents: true) }

      it_behaves_like "permit actions", :agent, :display?, :edit?, :create?, :update_teams?
    end

    context "allowed to manage access rights agent" do
      let(:agent) { create(:agent, role_in_territories: []) }
      let!(:access_rights) { create(:agent_territorial_access_right, agent: agent, territory: territory, allow_to_manage_access_rights: true) }

      it_behaves_like "permit actions", :agent, :display?, :edit?, :update_teams?
    end
  end
end
