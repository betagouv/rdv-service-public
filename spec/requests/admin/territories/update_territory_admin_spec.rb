# Ces specs couvrent les cas où le formulaire d'édition des droits d'accès (spec/features/territory_admins/agents/
# territory_admin_can_manage_agents_access_rights_spec.rb) désactive le champ concerné : impossible de les tester
# en visitant la page, on envoie donc directement la requête.

RSpec.describe "Update agent territorial access rights, cases the form doesn't allow" do
  let(:territory) { create(:territory) }
  let(:organisation) { create(:organisation, territory: territory) }
  let(:target_agent) { create(:agent, basic_role_in_organisations: [organisation]) }

  before { sign_in current_agent }

  context "when the agent can only manage teams in the current territory" do
    let(:current_agent) { create(:agent) }

    before do
      create(:agent_territorial_access_right, agent: current_agent, territory: territory, allow_to_manage_teams: true)
    end

    it "doesn't allow making an agent a territorial admin" do
      patch admin_territory_agent_territorial_access_right_path(territory_id: territory.id, id: target_agent.id),
            params: { agent_territorial_access_right: { territory_admin: "1" } }

      expect(target_agent.reload.territorial_admin_in?(territory)).to be false
    end

    it "doesn't allow editing another agent's specific rights" do
      create(:agent_territorial_access_right, agent: target_agent, territory: territory)

      patch admin_territory_agent_territorial_access_right_path(territory_id: territory.id, id: target_agent.id),
            params: { agent_territorial_access_right: { allow_to_manage_teams: "1" } }

      expect(target_agent.reload.access_rights_for_territory(territory).allow_to_manage_teams?).to be false
    end
  end

  context "when the agent only has allow_to_manage_access_rights in the current territory" do
    let(:current_agent) { create(:agent) }

    before do
      create(:agent_territorial_access_right, agent: current_agent, territory: territory, allow_to_manage_access_rights: true)
      create(:agent_territorial_access_right, agent: target_agent, territory: territory)
    end

    it "silently ignores an attempt to grant territory_admin" do
      patch admin_territory_agent_territorial_access_right_path(territory_id: territory.id, id: target_agent.id),
            params: { agent_territorial_access_right: { territory_admin: "1" } }

      expect(target_agent.reload.territorial_admin_in?(territory)).to be false
    end
  end

  context "when the agent is territory admin" do
    let(:current_agent) { create(:agent, admin_in_territories: [territory]) }

    it "silently ignores the 3 specific rights submitted alongside territory_admin" do
      patch admin_territory_agent_territorial_access_right_path(territory_id: territory.id, id: target_agent.id),
            params: { agent_territorial_access_right: { territory_admin: "1", allow_to_manage_teams: "1" } }

      target_agent.reload
      expect(target_agent.territorial_admin_in?(territory)).to be true
      expect(target_agent.access_rights_for_territory(territory)&.allow_to_manage_teams?).to be_falsey
    end
  end
end
