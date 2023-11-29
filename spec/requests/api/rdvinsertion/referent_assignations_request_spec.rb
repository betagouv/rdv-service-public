require "swagger_helper"

describe "Referent Assignation authentified API", swagger_doc: "v1/api.json" do
  with_examples

  path "/api/rdvinsertion/referent_assignations/create_many" do
    post "Ajouter un ou plusieurs référents à un utilisateur" do
      with_authentication

      tags "ReferentAssignations"
      produces "application/json"
      operationId "createReferentAssignations"
      description "Ajoute un ou plusieurs référents à un utilisateur"

      parameter name: "agent_ids[]", in: :query, schema: { type: :array, items: { type: :string } }, description: "ID des agents référents", example: "[1, 2]"
      parameter name: "user_id", in: :query, type: :integer, description: "ID de l'utilisateur", example: 12

      let!(:territory) { create(:territory) }
      let!(:organisation) { create(:organisation, territory: territory, verticale: "rdv_insertion") }
      let!(:other_organisation) { create(:organisation, territory: territory, verticale: "rdv_solidarites") }
      let!(:user) { create(:user, organisations: [organisation]) }
      let!(:agent1) { create(:agent, basic_role_in_organisations: [organisation]) }
      let!(:agent2) { create(:agent, basic_role_in_organisations: [other_organisation]) }
      let(:auth_headers) { api_auth_headers_for_agent(agent1) }
      let(:"access-token") { auth_headers["access-token"].to_s }
      let(:uid) { auth_headers["uid"].to_s }
      let(:client) { auth_headers["client"].to_s }

      response 200, "Ajouter un utilisateur à une ou plusieurs organisations" do
        let(:"agent_ids[]") { [agent1.id, agent2.id] }
        let(:user_id) { user.id }

        run_test!

        it { change(ReferentAssignation, :count).by(1) } # other_organisation is not in the same territory

        it { expect(user.reload.referent_agents).to include(agent1) }

        it { expect(user.reload.referent_agents).not_to include(agent2) }
      end

      it_behaves_like "an endpoint that returns 401 - unauthorized" do
        let(:"agent_ids[]") { [agent1.id, agent2.id] }
        let(:user_id) { user.id }
      end

      it_behaves_like "an endpoint that returns 404 - not found", "l'utilisateur n'a pas été trouvé" do
        let(:"agent_ids[]") { [agent1.id, agent2.id] }
        let(:user_id) { User.last.id + 1 }
      end
    end
  end
end
