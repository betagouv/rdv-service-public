RSpec.describe Admin::Territories::AgentsController do
  let!(:territory) { create(:territory) }
  let!(:current_agent) { create(:agent, role_in_territories: [territory]) }

  before { sign_in current_agent }

  describe "#index" do
    it "returns JSON list of agents" do
      organisation = create(:organisation, territory: territory)
      francis = create(:agent, :with_territory_access_rights, first_name: "Francis", last_name: "Factice", organisations: [organisation])

      get admin_territory_agents_path(territory_id: territory.id), params: { q: "fra" }, headers: { CONTENT_TYPE: "application/json", ACCEPT: "application/json" }
      expect(response.parsed_body).to eq({ "results" => [{ "id" => francis.id, "text" => "FACTICE Francis" }] })
    end
  end
end
