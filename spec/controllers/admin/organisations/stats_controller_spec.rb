RSpec.describe Admin::Organisations::StatsController do
  describe "#rdvs" do
    it "returns rdvs of the current organisation only" do
      travel_to(Time.zone.parse("2023-09-24"))
      organisation = create(:organisation)
      other_organisation = create(:organisation)
      agent = create(:agent, admin_role_in_organisations: [organisation, other_organisation])

      create(:rdv, organisation: organisation)
      create(:rdv, organisation: other_organisation)
      sign_in agent
      get :rdvs, params: { organisation_id: organisation.id, agent_id: agent.id, format: :json }

      expect(response).to be_successful

      expect(response.parsed_body).to eq(
        [
          { "data" => [["24/09/2023", 1]], "name" => "Agent (1)" },
        ]
      )
    end
  end
end
