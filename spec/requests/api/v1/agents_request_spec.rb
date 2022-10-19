# frozen_string_literal: true

describe "api/v1/agents requests", type: :request do
  describe "GET api/v1/agents" do
    subject { get api_v1_agents_path(params), headers: api_auth_headers_for_agent(agent) }

    context "some agents" do
      let!(:organisation) { create(:organisation) }
      let!(:organisation2) { create(:organisation) }
      let!(:organisation3) { create(:organisation) }
      let!(:agent) { create(:agent, admin_role_in_organisations: [organisation, organisation2]) }
      let!(:agent2) { create(:agent, basic_role_in_organisations: [organisation2]) }
      let!(:agent3) { create(:agent, basic_role_in_organisations: [organisation3]) }

      context "policy scoped agents" do
        let(:params) { {} }

        it "returns all agents of available organisations" do
          subject
          expect(response.status).to eq(200)
          expect(parsed_response_body["agents"].pluck("id")).to match_array([agent.id, agent2.id])
        end
      end

      context "filtered on organisation" do
        let(:params) { { organisation_id: organisation.id } }

        it "only includes specified organisation" do
          subject
          expect(response.status).to eq(200)
          expect(parsed_response_body["agents"].pluck("id")).to match_array([agent.id])
        end
      end
    end
  end
end
