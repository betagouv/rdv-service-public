require "swagger_helper"

RSpec.describe "Referent Assignation authentified API", swagger_doc: "v1/api.json" do
  with_examples

  path "/api/v1/referent_assignations" do
    post "Créer une assignation à un référent" do
      with_authentication

      tags "ReferentAssignation"
      produces "application/json"
      operationId "createReferentAssignation"
      description "Crée une assignation à un référent"

      parameter name: "agent_id", in: :query, type: :integer, description: "ID de l'agent", example: 14
      parameter name: "user_id", in: :query, type: :integer, description: "ID de l'utilisateur", example: 12

      let!(:territory) { create(:territory) }
      let!(:organisation) { create(:organisation, territory: territory) }
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
      let!(:user) { create(:user, organisations: [organisation]) }
      let!(:referent) { create(:agent, basic_role_in_organisations: [organisation]) }
      let(:auth_headers) { api_auth_headers_for_agent(agent) }
      let(:"access-token") { auth_headers["access-token"].to_s }
      let(:uid) { auth_headers["uid"].to_s }
      let(:client) { auth_headers["client"].to_s }
      let!(:agent_id) { referent.id }
      let!(:user_id) { user.id }

      response 200, "Crée et renvoie une assignation à un référent" do
        schema "$ref" => "#/components/schemas/referent_assignation_with_root"

        run_test!

        it { change(ReferentAssignation, :count).by(1) }

        it { expect(parsed_response_body.dig("referent_assignation", "user", "id")).to eq(user_id) }

        it { expect(parsed_response_body.dig("referent_assignation", "agent", "id")).to eq(agent_id) }

        it { expect(user.reload.referent_agents).to include(referent) }

        it "logs the API call" do
          expect(ApiCall.first.attributes.symbolize_keys).to include(
            controller_name: "referent_assignations",
            action_name: "create",
            agent_id: agent.id
          )
        end
      end

      it_behaves_like "an endpoint that returns 403 - forbidden", "l'agent.e n'a pas accès à l'organisation de l'utilisateur" do
        let!(:other_organisation) { create(:organisation) }
        let!(:agent) { create(:agent, basic_role_in_organisations: [other_organisation]) }
      end

      it_behaves_like "an endpoint that returns 403 - forbidden", "l'agent.e n'est pas sur le même territoire que le reférent" do
        let!(:other_territory) { create(:territory) }
        let!(:other_territory_organisation) { create(:organisation, territory: other_territory) }
        let!(:user) { create(:user, organisations: [organisation, other_territory_organisation]) }
        let!(:referent) { create(:agent, basic_role_in_organisations: [other_territory_organisation]) }
      end

      it_behaves_like "an endpoint that returns 401 - unauthorized"

      it_behaves_like "an endpoint that returns 422 - unprocessable_entity", "l'assignation existe déjà", false do
        let!(:referent_assignation) { create(:referent_assignation, user: user, agent: referent) }
      end
    end

    delete "Détruit une assignation à un référent" do
      with_authentication

      tags "ReferentAssignation"
      produces "application/json"
      operationId "deleteReferentAssignation"
      description "Détruit une assignation à un référent"

      parameter name: "agent_id", in: :query, type: :integer, description: "ID de l'agent", example: 14
      parameter name: "user_id", in: :query, type: :integer, description: "ID de l'utilisateur", example: 12

      let!(:territory) { create(:territory) }
      let!(:organisation) { create(:organisation, territory: territory) }
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
      let!(:user) { create(:user, organisations: [organisation]) }
      let!(:referent) { create(:agent, basic_role_in_organisations: [organisation]) }
      let!(:referent_assignation) { create(:referent_assignation, user: user, agent: referent) }
      let(:auth_headers) { api_auth_headers_for_agent(agent) }
      let(:"access-token") { auth_headers["access-token"].to_s }
      let(:uid) { auth_headers["uid"].to_s }
      let(:client) { auth_headers["client"].to_s }
      let!(:agent_id) { referent.id }
      let!(:user_id) { user.id }

      response 204, "Détruit une assignation à un référent" do
        run_test!

        it { change(ReferentAssignation, :count).by(-1) }

        it { expect(user.reload.referent_agents).not_to include(referent) }
      end

      it_behaves_like "an endpoint that returns 403 - forbidden", "l'agent.e n'a pas accès à l'organisation de l'utilisateur" do
        let!(:other_organisation) { create(:organisation) }
        let!(:agent) { create(:agent, basic_role_in_organisations: [other_organisation]) }
      end

      it_behaves_like "an endpoint that returns 403 - forbidden", "l'agent.e n'est pas sur le même territoire que le reférent" do
        let!(:other_territory) { create(:territory) }
        let!(:other_territory_organisation) { create(:organisation, territory: other_territory) }
        let!(:user) { create(:user, organisations: [organisation, other_territory_organisation]) }
        let!(:referent) { create(:agent, basic_role_in_organisations: [other_territory_organisation]) }
      end

      it_behaves_like "an endpoint that returns 401 - unauthorized"

      response 404, "l'assignation n'existe pas" do
        let!(:agent_id) { "inconnu" }

        run_test!
      end
    end
  end
end
