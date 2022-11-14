# frozen_string_literal: true

require "swagger_helper"

describe "Agents API", swagger_doc: "v1/api.json" do
  with_examples

  path "/api/v1/agents" do
    get "Lister les agent·es" do
      with_authentication
      with_pagination

      tags "Agent"
      produces "application/json"
      operationId "getAgents"
      description "Renvoie les agent·es des organisations accessibles, de manière paginée"

      parameter name: "organisation_id", in: :query, type: :integer, description: "L'ID d'une organisation donnée", example: "123", required: false

      let!(:organisation) { create(:organisation) }
      let!(:organisation2) { create(:organisation) }
      let!(:organisation3) { create(:organisation) }
      let!(:agent) { create(:agent, admin_role_in_organisations: [organisation, organisation2]) }
      let!(:agent2) { create(:agent, basic_role_in_organisations: [organisation2]) }
      let!(:agent3) { create(:agent, basic_role_in_organisations: [organisation3]) }

      let(:auth_headers) { api_auth_headers_for_agent(agent) }
      let(:"access-token") { auth_headers["access-token"].to_s }
      let(:uid) { auth_headers["uid"].to_s }
      let(:client) { auth_headers["client"].to_s }

      response 200, "Renvoie les agent·es" do
        let(:organisation_id) { organisation.id }

        schema "$ref" => "#/components/schemas/agents"

        run_test!

        it { expect(parsed_response_body["agents"].pluck("id")).to match_array([agent.id]) }
      end

      response 200, "policy scoped agents", document: false do
        schema "$ref" => "#/components/schemas/agents"

        run_test!

        it { expect(parsed_response_body["agents"].pluck("id")).to match_array([agent.id, agent2.id]) }
      end

      it_behaves_like "an authenticated endpoint"
    end
  end
end
