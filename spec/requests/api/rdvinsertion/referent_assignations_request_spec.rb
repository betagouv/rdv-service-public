require "swagger_helper"

RSpec.describe "Referent Assignation authentified API" do
  path "/api/rdvinsertion/referent_assignations/create_many" do
    post "Ajouter un ou plusieurs référents à un utilisateur" do
      with_shared_secret_authentication

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
      let!(:shared_secret) { "S3cr3T" }
      let(:auth_headers) { api_auth_headers_with_shared_secret(agent1, shared_secret) }
      let(:uid) { auth_headers["uid"].to_s }
      let(:"X-Agent-Auth-Signature") { auth_headers["X-Agent-Auth-Signature"].to_s }

      before do
        allow(Agent).to receive(:find_by).and_return(agent1)
        allow(ENV).to receive(:fetch).with("SHARED_SECRET_FOR_AGENTS_AUTH").and_return(shared_secret)
        allow(ActiveSupport::SecurityUtils).to receive(:secure_compare).and_return(true)
      end

      response 200, "Ajouter un utilisateur à une ou plusieurs organisations" do
        let(:"agent_ids[]") { [agent1.id, agent2.id] }
        let(:user_id) { user.id }

        run_test!

        it { change(ReferentAssignation, :count).by(1) } # other_organisation is not rdv-insertion

        it { expect(user.reload.referent_agents).to include(agent1) }

        it { expect(user.reload.referent_agents).not_to include(agent2) }

        it "logs the API call" do
          expect(ApiCall.first.attributes.symbolize_keys).to include(
            controller_name: "referent_assignations",
            action_name: "create_many",
            agent_id: agent1.id
          )
        end
      end

      context "when authentication fails" do
        let(:"agent_ids[]") { [agent1.id, agent2.id] }
        let(:user_id) { user.id }

        before do
          allow(ActiveSupport::SecurityUtils).to receive(:secure_compare).and_return(false)
        end

        it "returns a 401 unauthorized response" do
          post "/api/rdvinsertion/referent_assignations/create_many", params: { "agent_ids[]": [agent1.id, agent2.id], user_id: user.id }, headers: auth_headers

          expect(response).to have_http_status(:unauthorized)
        end
      end

      context "when user is not found" do
        let(:"agent_ids[]") { [agent1.id, agent2.id] }
        let(:user_id) { User.last.id + 1 }

        it "returns a 404 not found" do
          post "/api/rdvinsertion/referent_assignations/create_many", params: { "agent_ids[]": [agent1.id, agent2.id], user_id: user_id }, headers: auth_headers

          expect(response).to have_http_status(:not_found)
          expect(response.body).to include("not_found")
        end
      end
    end
  end
end
