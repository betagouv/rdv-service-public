RSpec.describe "RDV API" do
  let!(:oauth_token) do
    create(:access_token, resource_owner_id: agent.id, application:)
  end
  let(:headers) do
    {
      "Content-Type": "application/json",
      Authorization: "Bearer #{oauth_token.plaintext_token}",
    }
  end
  let(:application) { create(:oauth_application) }

  describe "#index" do
    let(:motif) { create(:motif, organisation: organisation, service: service) }
    let(:service) { create(:service) }
    let(:organisation) { create(:organisation) }

    let(:agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
    let(:other_agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }

    let!(:rdv_with_user_and_agent) { create(:rdv, organisation: organisation, motif: motif, users: [user], agents: [agent]) }
    let!(:rdv_with_user_and_other_agent) { create(:rdv, organisation: organisation, motif: motif, users: [user], agents: [other_agent]) }

    let!(:rdv_with_other_user_and_agent) { create(:rdv, organisation: organisation, motif: motif, users: [other_user], agents: [agent]) }
    let!(:rdv_with_other_user_and_other_agent) { create(:rdv, organisation: organisation, motif: motif, users: [other_user], agents: [other_agent]) }

    it "filters by agent and user id" do
      get "/api/v1/rdvs", headers: headers, params: { user_id: user.id, agent_id: agent.id }, as: :json
      expect(parsed_response_body["rdvs"].count).to eq 1
      expect(parsed_response_body["rdvs"].first["id"]).to eq rdv_with_user_and_agent.id
    end
  end
end
