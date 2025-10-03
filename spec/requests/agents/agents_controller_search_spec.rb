RSpec.describe Agents::AgentsController, "#search" do
  let!(:territory) { create(:territory) }
  let!(:organisation) { create(:organisation, territory: territory) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }

  before do
    sign_in agent
  end

  it "works" do
    # The policy is tested separately, but let's make sure it is used.
    expect(Agent::AgentPolicy::Scope).to receive(:new).and_call_original

    get agents_ajax_agents_search_path(organisation_id: organisation), as: :json
    expect(parsed_response_body[:results]).to eq([{ "id" => agent.id, "text" => agent.reverse_full_name_or_email }])
  end
end
