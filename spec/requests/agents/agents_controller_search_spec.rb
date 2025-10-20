RSpec.describe Agents::AgentsController, "#search" do
  let!(:territory) { create(:territory) }
  let!(:organisation) { create(:organisation, territory: territory) }
  let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

  before do
    sign_in agent
  end

  it "works" do
    # The policy is tested separately, but let's make sure it is used.
    expect(Agent::AgentPolicy::Scope).to receive(:new).and_call_original

    francis = create(:agent, first_name: "Francis", last_name: "Factice", admin_role_in_organisations: [organisation])
    get agents_ajax_agents_search_path(organisation_id: organisation, term: "fra"), as: :json
    expect(parsed_response_body[:results]).to eq([{ "id" => francis.id, "text" => "FACTICE Francis" }])
  end

  context "quand un des agents n'a pas encore accepté son invitation" do
    let!(:unconfirmed_agent) { create(:agent, :not_confirmed, first_name: "Francis", admin_role_in_organisations: [organisation]) }

    it "renvoie son adresse mail" do
      get agents_ajax_agents_search_path(organisation_id: organisation, term: "fra"), as: :json
      expect(parsed_response_body[:results]).to include({ "id" => unconfirmed_agent.id, "text" => unconfirmed_agent.email })
    end
  end

  context "quand un agent est présent dans plusieurs de mes orgas" do
    let!(:orga_1) { create(:organisation) }
    let!(:orga_2) { create(:organisation) }
    let!(:agent) { create(:agent, admin_role_in_organisations: [orga_1, orga_2]) }
    let!(:francis) { create(:agent, first_name: "Francis", last_name: "Factice", basic_role_in_organisations: [orga_1, orga_2]) }

    it "ne s'affiche qu'une seule fois dans la liste" do
      get agents_ajax_agents_search_path(organisation_id: [orga_1, orga_2], term: "fra"), as: :json
      expect(parsed_response_body[:results].sole).to match({ "id" => francis.id, "text" => "FACTICE Francis" })
    end
  end
end
