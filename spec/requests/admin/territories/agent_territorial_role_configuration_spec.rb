# frozen_string_literal: true

RSpec.describe "Configure le statut d'aministrateur de territoire d'un agent", type: :request do
  include Rails.application.routes.url_helpers

  let(:territory) { create(:territory) }
  let(:organisation) { create(:organisation, territory: territory) }

  context "with an territorial admin" do
    let(:connected_admin) { create(:agent, basic_role_in_organisations: [organisation], role_in_territories: [territory]) }
    let!(:agent_territorial_access_right) do
      create(:agent_territorial_access_right, agent: connected_admin, territory: territory, allow_to_manage_access_rights: true)
    end

    before { sign_in connected_admin }

    it "show territory admin informations" do
      agent = create(:agent, basic_role_in_organisations: [organisation], role_in_territories: [])
      create(:agent_territorial_access_right, agent: agent, territory: territory)
      get edit_admin_territory_agent_path(territory, agent)
      expect(response).to be_successful
      expect(response.body).to include("Administrateur de territoire")
    end

    it "set territory admin" do
      agent = create(:agent, basic_role_in_organisations: [organisation], role_in_territories: [])
      post admin_territory_agent_territorial_roles_path(territory), params: { agent_territorial_role: { agent_id: agent.id } }
      expect(response).to redirect_to(edit_admin_territory_agent_path(territory, agent))
      expect(agent.reload).to be_territorial_admin_in(territory)
    end

    it "unset territory admin" do
      agent = create(:agent, basic_role_in_organisations: [organisation], role_in_territories: [territory])
      role = agent.territorial_roles.first
      delete admin_territory_agent_territorial_role_path(territory, role)
      expect(response).to redirect_to(edit_admin_territory_agent_path(territory, agent))
      expect(agent.reload).not_to be_territorial_admin_in(territory)
    end
  end

  context "with a basic agent" do
    let(:connected_agent) { create(:agent, basic_role_in_organisations: [organisation], role_in_territories: []) }
    let!(:agent_territorial_access_right) do
      create(:agent_territorial_access_right, agent: connected_agent, territory: territory, allow_to_manage_access_rights: false)
    end

    before { sign_in connected_agent }

    it "redirect to root path" do
      agent = create(:agent, basic_role_in_organisations: [organisation], role_in_territories: [])
      create(:agent_territorial_access_right, agent: agent, territory: territory)
      get edit_admin_territory_agent_path(territory, agent)
      expect(response).to redirect_to(root_path)
    end
  end
end
