RSpec.describe "CRUDS teams configuration", type: :request do
  describe "GET admin/territories/:territory_id/teams" do
    it "returns all teams" do
      territory = create(:territory)
      agent = create(:agent)
      create(:agent_territorial_access_right, allow_to_manage_teams: true, agent: agent, territory: territory)

      sign_in agent

      teams = create_list(:team, 3, territory: territory)

      get admin_territory_teams_path(territory)

      expect(response).to be_successful
      expect(assigns(:teams)).to match_array(teams)
    end

    it "returns searched teams" do
      territory = create(:territory)
      agent = create(:agent)
      create(:agent_territorial_access_right, allow_to_manage_teams: true, agent: agent, territory: territory)

      sign_in agent

      create(:team, territory: territory, name: "other name")
      matching_team = create(:team, territory: territory, name: "First Groupe")

      get admin_territory_teams_path(territory, term: "first")

      expect(response).to be_successful
      expect(assigns(:teams)).to eq([matching_team])
    end
  end
end
