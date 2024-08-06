RSpec.describe Configuration::AgentPolicy, type: :policy do
  subject { described_class }

  # target_agent = pundit record = l’agent sur lequel on teste les permissions
  # current_agent = pundit user = l’agent connecté qui essaie de faire une action

  context "no rights at all" do
    let(:territory) { create(:territory) }
    let(:current_agent) { create(:agent, role_in_territories: []) }
    let(:target_agent) { create(:agent) }
    let(:pundit_context) { AgentTerritorialContext.new(current_agent, territory) }

    it_behaves_like "not permit actions", :target_agent, :edit?, :update_teams?, :update_services?, :create?
  end

  context "current_agent is territory admin, target_agent has a basic role in this territory" do
    let(:territory) { create(:territory) }
    let(:current_agent) { create(:agent, role_in_territories: [territory]) }
    let(:organisation) { create(:organisation, territory:) }
    let(:target_agent) { create(:agent, basic_role_in_organisations: [organisation]) }
    let(:pundit_context) { AgentTerritorialContext.new(current_agent, territory) }

    it_behaves_like "permit actions", :target_agent, :edit?, :update_services?, :create?
    it_behaves_like "not permit actions", :target_agent, :update_teams?
  end

  context "current_agent is territory admin, target_agent has a basic role in different territory" do
    let(:territory) { create(:territory) }
    let(:current_agent) { create(:agent, role_in_territories: [territory]) }
    let(:other_territory) { create(:territory) }
    let(:organisation) { create(:organisation, territory: other_territory) }
    let(:target_agent) { create(:agent, basic_role_in_organisations: [organisation]) }
    let(:pundit_context) { AgentTerritorialContext.new(current_agent, territory) }

    it_behaves_like "not permit actions", :target_agent, :edit?, :update_services?, :create?
    it_behaves_like "not permit actions", :target_agent, :update_teams?
  end

  context "current_agent is territory admin, target_agent is also territory admin" do
    let(:territory) { create(:territory) }
    let(:current_agent) { create(:agent, role_in_territories: [territory]) }
    let(:target_agent) { create(:agent, role_in_territories: [territory]) }
    let(:pundit_context) { AgentTerritorialContext.new(current_agent, territory) }

    it_behaves_like "permit actions", :target_agent, :edit?, :update_services?, :create?
    it_behaves_like "not permit actions", :target_agent, :update_teams?
  end

  context "current_agent has allow_to_manage_access_rights in a territory, target_agent has a basic role in this territory" do
    let(:territory) { create(:territory) }
    let(:current_agent) { create(:agent, role_in_territories: []) }
    let(:pundit_context) { AgentTerritorialContext.new(current_agent, territory) }
    let(:organisation) { create(:organisation, territory:) }
    let(:target_agent) { create(:agent, basic_role_in_organisations: [organisation]) }

    before { create(:agent_territorial_access_right, agent: current_agent, territory: territory, allow_to_manage_access_rights: true) }

    it_behaves_like "permit actions", :target_agent, :edit?, :update_services?
    it_behaves_like "not permit actions", :target_agent, :update_teams?, :create?
  end

  context "current_agent has allow_to_manage_teams access right in a territory, target_agent has a basic role in this territory" do
    let(:territory) { create(:territory) }
    let(:current_agent) { create(:agent, role_in_territories: []) }
    let(:pundit_context) { AgentTerritorialContext.new(current_agent, territory) }
    let(:organisation) { create(:organisation, territory:) }
    let(:target_agent) { create(:agent, basic_role_in_organisations: [organisation]) }

    before { create(:agent_territorial_access_right, agent: current_agent, territory: territory, allow_to_manage_teams: true) }

    it_behaves_like "permit actions", :target_agent, :edit?, :update_teams?, :update_services?
    it_behaves_like "not permit actions", :target_agent, :create?
  end

  context "current_agent has allow_to_invite_agents access right in a territory, target_agent has a basic role in this territory" do
    let(:territory) { create(:territory) }
    let(:current_agent) { create(:agent, role_in_territories: []) }
    let(:pundit_context) { AgentTerritorialContext.new(current_agent, territory) }
    let(:organisation) { create(:organisation, territory:) }
    let(:target_agent) { create(:agent, basic_role_in_organisations: [organisation]) }

    before { create(:agent_territorial_access_right, agent: current_agent, territory: territory, allow_to_invite_agents: true) }

    it_behaves_like "permit actions", :target_agent, :edit?, :update_services?, :create?
    it_behaves_like "not permit actions", :target_agent, :update_teams?
  end

  context "current_agent is territory admin, target_agent is a new record without any role" do
    let(:territory) { create(:territory) }
    let(:current_agent) { create(:agent, role_in_territories: [territory]) }
    let(:target_agent) { build(:agent) }
    let(:pundit_context) { AgentTerritorialContext.new(current_agent, territory) }

    it_behaves_like "not permit actions", :target_agent, :create?
  end

  context "current_agent is territory admin, target_agent is a new record with a role in an organisation of this territory" do
    let(:territory) { create(:territory) }
    let(:current_agent) { create(:agent, role_in_territories: [territory]) }
    let!(:organisation) { create(:organisation, territory:) }
    # we cannot use the factory trait basic_roles_in_organisations because it works only with create, not build
    let(:target_agent) { build(:agent, organisation_ids: [organisation.id]) }
    let(:pundit_context) { AgentTerritorialContext.new(current_agent, territory) }

    it_behaves_like "permit actions", :target_agent, :create?
  end

  context "current_agent is territory admin, target_agent is a new record with a role in an organisation from another territory" do
    let(:territory) { create(:territory) }
    let(:current_agent) { create(:agent, role_in_territories: [territory]) }
    let!(:other_territory) { create(:territory) }
    let!(:organisation) { create(:organisation, territory: other_territory) }
    # we cannot use the factory trait basic_roles_in_organisations because it works only with create, not build
    let(:target_agent) { build(:agent, organisation_ids: [organisation.id]) }
    let(:pundit_context) { AgentTerritorialContext.new(current_agent, territory) }

    it_behaves_like "not permit actions", :target_agent, :create?
  end

  context "current_agent is territory A admin, target_agent is a new record with 2 roles but one of them is in another territory" do
    let(:territory) { create(:territory) }
    let(:current_agent) { create(:agent, role_in_territories: [territory]) }
    let!(:other_territory) { create(:territory) }
    let!(:organisation1) { create(:organisation, territory:) }
    let!(:organisation2) { create(:organisation, territory: other_territory) }
    # we cannot use the factory trait basic_roles_in_organisations because it works only with create, not build
    let(:target_agent) { build(:agent, organisation_ids: [organisation1.id, organisation2.id]) }
    let(:pundit_context) { AgentTerritorialContext.new(current_agent, territory) }

    it_behaves_like "not permit actions", :target_agent, :create?
  end
end
