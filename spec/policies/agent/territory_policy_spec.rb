RSpec.describe Agent::TerritoryPolicy, type: :policy do
  subject { described_class }

  let(:territory) { create(:territory) }
  let(:pundit_context) { agent }

  describe "agent with" do
    context "no admin access to this territory and no access_rights" do
      let(:agent) { create(:agent, role_in_territories: []) }
      let!(:access_rights) { create(:agent_territorial_access_right, agent: agent, territory: territory) }

      it_behaves_like "not permit actions",
                      :territory,
                      :show?,
                      :update?,
                      :edit?,
                      :allow_to_manage_access_rights?,
                      :allow_to_invite_agents?,
                      :allow_to_manage_teams?
    end

    context "admin access to this territory" do
      let(:territory) { create(:territory) }
      let(:agent) { create(:agent, role_in_territories: [territory]) }
      let!(:access_rights) { create(:agent_territorial_access_right, agent: agent, territory: territory) }

      it_behaves_like "permit actions",
                      :territory,
                      :show?,
                      :update?,
                      :edit?

      it_behaves_like "not permit actions", :territory,
                      :allow_to_manage_access_rights?,
                      :allow_to_invite_agents?,
                      :allow_to_manage_teams?
    end

    context "allowed to manage teams access right" do
      let(:agent) { create(:agent, role_in_territories: []) }
      let!(:access_rights) { create(:agent_territorial_access_right, agent: agent, territory: territory, allow_to_manage_teams: true) }

      it_behaves_like "permit actions", :territory, :show?, :allow_to_manage_teams?

      it_behaves_like "not permit actions", :territory, :update?, :edit?, :allow_to_manage_access_rights?, :allow_to_invite_agents?
    end

    context "allowed to manage access rights access right" do
      let(:agent) { create(:agent, role_in_territories: []) }
      let!(:access_rights) { create(:agent_territorial_access_right, agent: agent, territory: territory, allow_to_manage_access_rights: true) }

      it_behaves_like "permit actions", :territory, :show?, :allow_to_manage_access_rights?

      it_behaves_like "not permit actions", :territory, :update?, :edit?, :allow_to_invite_agents?, :allow_to_manage_teams?
    end

    context "allowed to invite agents access right" do
      let(:agent) { create(:agent, role_in_territories: []) }
      let!(:access_rights) { create(:agent_territorial_access_right, agent: agent, territory: territory, allow_to_invite_agents: true) }

      it_behaves_like "permit actions", :territory, :show?, :allow_to_invite_agents?

      it_behaves_like "not permit actions", :territory, :update?, :edit?, :allow_to_manage_teams?, :allow_to_manage_access_rights?
    end
  end
end

RSpec.describe Agent::TerritoryPolicy::Scope, type: :policy do
  describe "#resolve?" do
    subject do
      described_class.new(agent, Territory).resolve
    end

    context "many possible cases" do
      let!(:agent) { create(:agent) }

      let!(:territory_no_rights_in_db) do
        create(:territory, name: "Territoire où je n'ai aucun droit")
      end

      let!(:territory_allow_nothing) do
        create(:territory, name: "Territoire ou j'ai un AgentTerritorialAccessRight avec tout à false").tap do |territory|
          agent.agent_territorial_access_rights.create!(territory:)
        end
      end

      let!(:territory_with_role) do
        create(:territory, name: "Territoire ou j'ai un AgentTerritorialRole").tap do |territory|
          agent.territorial_roles.create!(territory:)
        end
      end

      let!(:territory_manage_teams) do
        create(:territory, name: "Territoire ou j'ai un AgentTerritorialAccessRight avec allow_to_manage_teams: true").tap do |territory|
          agent.agent_territorial_access_rights.create!(territory:, allow_to_manage_teams: true)
        end
      end
      let!(:territory_invite_agents) do
        create(:territory, name: "Territoire ou j'ai un AgentTerritorialAccessRight avec allow_to_invite_agents: true").tap do |territory|
          agent.agent_territorial_access_rights.create!(territory:, allow_to_invite_agents: true)
        end
      end
      let!(:territory_manage_access_rights) do
        create(:territory, name: "Territoire ou j'ai un AgentTerritorialAccessRight avec allow_to_manage_access_rights: true").tap do |territory|
          agent.agent_territorial_access_rights.create!(territory:, allow_to_invite_agents: true)
        end
      end

      let!(:territory_with_role_and_rights) do
        create(:territory, name: "Territoire ou j'ai un à la fois un role et des rights").tap do |territory|
          agent.territorial_roles.create!(territory:)
          agent.agent_territorial_access_rights.create!(territory:, allow_to_manage_access_rights: true)
        end
      end

      let!(:territory_with_role_for_another_agent) do
        create(:territory, name: "Territoire où quelqu'un d'autre a un AgentTerritorialRole").tap do |territory|
          create(:agent).territorial_roles.create!(territory:)
        end
      end

      let!(:territory_with_rights_for_another_agent) do
        create(:territory, name: "Territoire où quelqu'un d'autre a un AgentTerritorialAccessRight avec allow_to_manage_teams: true").tap do |territory|
          create(:agent).agent_territorial_access_rights.create!(territory:, allow_to_manage_teams: true)
        end
      end

      it "includes any territory where I either have a role or any right" do
        expect(subject).to contain_exactly(
          territory_with_role,
          territory_manage_teams,
          territory_invite_agents,
          territory_manage_access_rights,
          territory_with_role_and_rights
        )
      end
    end
  end
end
