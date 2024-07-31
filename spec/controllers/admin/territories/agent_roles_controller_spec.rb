RSpec.describe Admin::Territories::AgentRolesController, type: :controller do
  # Le territoire doit avoir au moins un agent admin de territoire restant
  let!(:territory) { create(:territory).tap { |t| t.roles.create!(agent: create(:agent)) } }

  describe "POST #update" do
    it "changes role and redirect to territorial agent edit" do
      agent = create(:agent, role_in_territories: [territory])
      create(:agent_territorial_access_right, allow_to_manage_teams: true, agent: agent)
      organisation = create(:organisation, territory: territory)
      agent_role = create(:agent_role, agent: agent, access_level: "basic")
      sign_in agent

      expect do
        post :update, params: { territory_id: territory.id, id: agent_role.id, agent_role: { access_level: "admin" } }
      end.to change { agent_role.reload.access_level }.from(AgentRole::ACCESS_LEVEL_BASIC).to(AgentRole::ACCESS_LEVEL_ADMIN)

      expect(response).to redirect_to(edit_admin_territory_agent_path(territory, agent))
    end
  end

  describe "POST #create" do
    it "redirect to territorial agent edit on creation success" do
      organisation = create(:organisation, territory: territory)
      agent = create(:agent, role_in_territories: [territory])
      create(:agent_territorial_access_right, allow_to_manage_teams: true, agent: agent)
      other_agent = create(:agent, organisations: [])
      sign_in agent

      post :create, params: { territory_id: territory.id, agent_role: { access_level: "admin", agent_id: other_agent.id, organisation_id: organisation.id } }
      expect(response).to redirect_to(edit_admin_territory_agent_path(territory, other_agent))
    end
  end

  describe "#destoy" do
    it "redirect to territorial_agent_edit on success if agent has another organisation" do
      organisation = create(:organisation, territory: territory)
      organisation2 = create(:organisation, territory: territory)
      agent = create(:agent, role_in_territories: [territory])
      create(:agent_territorial_access_right, territory: territory, agent: agent)
      agent_role = create(:agent_role, organisation: organisation, agent: agent, access_level: "basic")
      create(:agent_role, organisation: organisation2, agent: agent, access_level: "basic")

      last_agent = create(:agent)
      create(:agent_territorial_access_right, territory: territory, agent: last_agent)
      create(:agent_role, organisation: organisation, agent: last_agent, access_level: "admin")

      sign_in agent

      delete :destroy, params: { territory_id: territory.id, id: agent_role.id }
      expect(response).to redirect_to(edit_admin_territory_agent_path(territory, agent))
    end

    it "redirect to territorial_agent_edit on success if it the last organisation" do
      organisation = create(:organisation, territory: territory)
      agent = create(:agent, role_in_territories: [territory])
      create(:agent_territorial_access_right, territory: territory, agent: agent)
      agent_role = create(:agent_role, organisation: organisation, agent: agent, access_level: "basic")

      last_agent = create(:agent)
      create(:agent_territorial_access_right, territory: territory, agent: last_agent)
      create(:agent_role, organisation: organisation, agent: last_agent, access_level: "admin")

      sign_in agent

      delete :destroy, params: { territory_id: territory.id, id: agent_role.id }
      expect(response).to redirect_to(admin_territory_agents_path(territory))
    end

    it "destroy agent_role" do
      organisation = create(:organisation, territory: territory)
      agent = create(:agent, role_in_territories: [territory])
      create(:agent_territorial_access_right, territory: territory, agent: agent)
      agent_role = create(:agent_role, organisation: organisation, agent: agent, access_level: "basic")

      # Il doit toujours y avoir un dernier admin dans une organisation pour le moment
      last_agent = create(:agent)
      create(:agent_territorial_access_right, territory: territory, agent: last_agent)
      create(:agent_role, organisation: organisation, agent: last_agent, access_level: "admin")

      sign_in agent

      expect do
        delete :destroy, params: { territory_id: territory.id, id: agent_role.id }
      end.to change(AgentRole, :count).from(2).to(1)
    end
  end
end
