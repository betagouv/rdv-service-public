# frozen_string_literal: true

RSpec.describe Admin::Territories::AgentsController, type: :controller do
  let(:territory) { create(:territory, departement_number: "62") }
  let(:organisation) { create(:organisation, territory: territory) }

  describe "#index" do
    it "assigns territory's agents" do
      agent = create(:agent, admin_role_in_organisations: [organisation], role_in_territories: [territory])
      other_agent = create(:agent, basic_role_in_organisations: [organisation])
      sign_in agent

      get :index, params: { territory_id: territory.id }
      expect(assigns(:agents)).to eq([agent, other_agent])
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
