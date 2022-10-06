# frozen_string_literal: true

describe Admin::Territories::AgentsController, type: :controller do
  let(:territory) { create(:territory, departement_number: "62") }
  let(:organisation) { create(:organisation, territory: territory) }

  describe "#index" do
    it "assigns territory's agents" do
      agent = create(:agent, last_name: "Z", admin_role_in_organisations: [organisation], role_in_territories: [territory])
      create(:agent_territorial_access_right, agent: agent, territory: territory)
      other_agent = create(:agent, last_name: "B", basic_role_in_organisations: [organisation])
      create(:agent_territorial_access_right, agent: other_agent, territory: territory)
      sign_in agent

      get :index, params: { territory_id: territory.id }
      expect(assigns(:agents)).to match_array([other_agent, agent])
    end

    it "filter assigns territory's agents with search params" do
      zarg = create(:agent, last_name: "Zarg", admin_role_in_organisations: [organisation], role_in_territories: [territory])
      create(:agent_territorial_access_right, agent: zarg, territory: territory)
      blot = create(:agent, last_name: "Blot", basic_role_in_organisations: [organisation])
      create(:agent_territorial_access_right, agent: blot, territory: territory)
      sign_in zarg

      get :index, params: { territory_id: territory.id, q: "zarg" }
      expect(assigns(:agents)).to eq([zarg])
    end
  end

  describe "#edit" do
    it "assigns agent" do
      agent = create(:agent, admin_role_in_organisations: [organisation], role_in_territories: [territory])
      sign_in agent

      get :edit, params: { territory_id: territory.id, id: agent.id }
      expect(assigns(:agent)).to eq(agent)
    end
  end

  describe "#update" do
    it "redirect to agents index" do
      agent = create(:agent, admin_role_in_organisations: [organisation], role_in_territories: [territory], teams: [])
      team = create(:team, territory: territory)
      sign_in agent

      post :update, params: { territory_id: territory.id, id: agent.id, agent: { team_ids: [team.id] } }
      expect(response).to redirect_to(admin_territory_agents_path)
    end

    it "update agent's teams" do
      agent = create(:agent, admin_role_in_organisations: [organisation], role_in_territories: [territory], teams: [])
      team = create(:team, territory: territory)
      sign_in agent

      post :update, params: { territory_id: territory.id, id: agent.id, agent: { team_ids: [team.id] } }
      expect(agent.reload.teams).to eq([team])
    end
  end
end
