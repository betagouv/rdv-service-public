require "swagger_helper"

RSpec.describe "Teams authentified API", swagger_doc: "v1/api.json" do
  with_examples

  path "/api/v1/teams" do
    get "Lister les équipes" do
      with_authentication

      tags "Teams"
      produces "application/json"
      operationId "getTeams"
      description "Renvoie toutes les équipes de tous les espaces auquel l'agent authentifié a accès."

      let(:territory) { territories(:default_territory) }
      let(:other_territory) { create(:territory) }
      let(:organisation) { create(:organisation, territory: territory) }
      let!(:agent) { create(:agent, :with_territory_access_rights, organisations: [organisation]) }
      let(:agents) { create_list(:agent, 3, organisations: [organisation]) }
      let!(:team) { create(:team, territory: territory, agents: agents) }
      let!(:other_team) { create(:team, territory: other_territory) }

      let(:access_basic_agent) { api_auth_headers_for_agent(agent) }
      let(:"access-token") { access_basic_agent["access-token"].to_s }
      let(:uid) { access_basic_agent["uid"].to_s }
      let(:client) { access_basic_agent["client"].to_s }

      response 200, "Renvoie les équipes" do
        schema "$ref" => "#/components/schemas/teams"

        run_test!

        it "returns teams" do
          expect(response.parsed_body["teams"].pluck("id")).to contain_exactly(team.id)
        end

        it "returns agents in teams" do
          expect(response.parsed_body["teams"].first["agents"].pluck("id")).to match_array(agents.pluck(:id))
        end
      end

      it_behaves_like "an endpoint that returns 401 - unauthorized"
    end
  end
end
