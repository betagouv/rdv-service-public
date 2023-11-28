require "swagger_helper"

describe "Referent Assignation authentified API", swagger_doc: "v1/api.json" do
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

  path "/api/v1/referent_assignations/upsert_many" do
    post "Ajouter un ou plusieurs référents à un utilisateur" do
      with_authentication

      tags "ReferentAssignations"
      produces "application/json"
      operationId "createReferentAssignations"
      description "Ajoute un ou plusieurs référents à un utilisateur"

      parameter name: "agent_ids[]", in: :query, schema: { type: :array, items: { type: :string } }, description: "ID des agents référents", example: "[1, 2]"
      parameter name: "user_id", in: :query, type: :integer, description: "ID de l'utilisateur", example: 12

      let!(:territory) { create(:territory) }
      let!(:other_territory) { create(:territory) }
      let!(:organisation) { create(:organisation, territory: territory) }
      let!(:other_organisation) { create(:organisation, territory: other_territory) }
      let!(:user) { create(:user, organisations: [organisation]) }
      let!(:agent1) { create(:agent, basic_role_in_organisations: [organisation]) }
      let!(:agent2) { create(:agent, basic_role_in_organisations: [other_organisation]) }
      let(:auth_headers) { api_auth_headers_for_agent(agent1) }
      let(:"access-token") { auth_headers["access-token"].to_s }
      let(:uid) { auth_headers["uid"].to_s }
      let(:client) { auth_headers["client"].to_s }

      response 200, "Ajouter un utilisateur à une ou plusieurs organisations et renvoie l'utilisateur" do
        let(:"agent_ids[]") { [agent1.id, agent2.id] }
        let(:user_id) { user.id }

        let(:updated_user) do
          User.find_by(id: parsed_response_body.dig("user", "id"))
        end

        schema "$ref" => "#/components/schemas/user_with_root"

        run_test!

        it { change(ReferentAssignation, :count).by(1) } # other_organisation is not in the same territory

        it { expect(updated_user).to eq(user) }

        it { expect(updated_user.reload.referent_agents).to include(agent1) }

        it { expect(updated_user.reload.referent_agents).not_to include(agent2) }
      end

      it_behaves_like "an endpoint that returns 401 - unauthorized" do
        let(:"agent_ids[]") { [agent1.id, agent2.id] }
        let(:user_id) { user.id }
      end

      it_behaves_like "an endpoint that returns 422 - unprocessable_entity", "l'utilisateur n'a pas pu être synchronisé avec ses organisations", true do
        let(:"agent_ids[]") { [agent1.id, agent2.id] }
        let(:user_id) { User.last.id + 1 }
      end
    end
  end
end
