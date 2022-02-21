# frozen_string_literal: true

describe Admin::Territories::TeamsController, type: :controller do
  let(:territory) { create(:territory, departement_number: "62") }
  let(:organisation) { create(:organisation, territory: territory) }

  describe "#index" do
    it "assigns territory's teams" do
      agent = create(:agent, admin_role_in_organisations: [organisation], role_in_territories: [territory])
      team = create(:team, territory: territory)
      create(:team, territory: create(:territory))
      sign_in agent

      get :index, params: { territory_id: territory.id }
      expect(assigns(:teams)).to eq([team])
    end

    it "filters territory's teams with search params" do
      agent = create(:agent, admin_role_in_organisations: [organisation], role_in_territories: [territory])
      team = create(:team, territory: territory, name: "first team")
      create(:team, territory: territory, name: "second")
      create(:team, territory: create(:territory))
      sign_in agent

      get :index, params: { territory_id: territory.id, search: "first" }
      expect(assigns(:teams)).to eq([team])
    end
  end

  describe "#new" do
    it "assigns new team" do
      agent = create(:agent, admin_role_in_organisations: [organisation], role_in_territories: [territory])
      sign_in agent

      get :new, params: { territory_id: territory.id }
      expect(assigns(:team)).to be_a(Team)
    end
  end

  describe "#create" do
    it "create a team" do
      agent = create(:agent, admin_role_in_organisations: [organisation], role_in_territories: [territory])
      sign_in agent
      expect do
        post :create, params: { territory_id: territory.id, team: { name: "UbberTeam" } }
      end.to change(Team, :count).by(1)
    end

    it "redirect to teams index" do
      agent = create(:agent, admin_role_in_organisations: [organisation], role_in_territories: [territory])
      sign_in agent
      post :create, params: { territory_id: territory.id, team: { name: "UbberTeam" } }
      expect(response).to redirect_to(admin_territory_teams_path)
    end
  end

  describe "#edit" do
    it "assigns new team" do
      agent = create(:agent, admin_role_in_organisations: [organisation], role_in_territories: [territory])
      team = create(:team, territory: territory)
      sign_in agent

      get :edit, params: { territory_id: territory.id, id: team.id }
      expect(assigns(:team)).to be_a(Team)
    end
  end

  describe "#update" do
    it "redirect to teams index" do
      agent = create(:agent, admin_role_in_organisations: [organisation], role_in_territories: [territory])
      team = create(:team, territory: territory)
      sign_in agent

      post :update, params: { territory_id: territory.id, id: team.id, team: { name: "otherName" } }
      expect(response).to redirect_to(admin_territory_teams_path)
    end

    it "update team" do
      agent = create(:agent, admin_role_in_organisations: [organisation], role_in_territories: [territory])
      team = create(:team, territory: territory)
      sign_in agent

      post :update, params: { territory_id: territory.id, id: team.id, team: { name: "otherName" } }
      expect(team.reload.name).to eq("otherName")
    end
  end

  describe "#destroy" do
    it "redirect to teams index" do
      agent = create(:agent, admin_role_in_organisations: [organisation], role_in_territories: [territory])
      team = create(:team, territory: territory)
      sign_in agent

      post :destroy, params: { territory_id: territory.id, id: team.id }
      expect(response).to redirect_to(admin_territory_teams_path)
    end

    it "destroy team" do
      agent = create(:agent, admin_role_in_organisations: [organisation], role_in_territories: [territory])
      team = create(:team, territory: territory)
      sign_in agent
      expect  do
        post :destroy, params: { territory_id: territory.id, id: team.id, team: { name: "otherName" } }
      end.to change(Team, :count).by(-1)
    end
  end

  describe "#search" do
    it "successful" do
      agent = create(:agent, admin_role_in_organisations: [organisation], role_in_territories: [territory])
      sign_in agent
      get :search, params: { territory_id: territory.id, term: "bla", format: "json" }
      expect(response).to be_successful
    end

    it "assigns teams" do
      agent = create(:agent, admin_role_in_organisations: [organisation], role_in_territories: [territory])
      sign_in agent
      team = create(:team, name: "bla", territory: organisation.territory)
      get :search, params: { territory_id: territory.id, term: "bla", format: "json" }
      expect(assigns(:teams)).to eq([team])
    end
  end
end
