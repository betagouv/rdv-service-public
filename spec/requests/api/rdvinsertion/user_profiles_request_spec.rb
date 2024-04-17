require "swagger_helper"

RSpec.describe "User Profile authentified API", swagger_doc: "v1/api.json" do
  with_examples

  path "/api/rdvinsertion/user_profiles/create_many" do
    post "Ajouter un utilisateur à une ou plusieurs organisations" do
      with_shared_secret_authentication

      tags "UserProfiles"
      produces "application/json"
      operationId "createUserProfiles"
      description "Ajoute un utilisateur à une ou plusieurs organisations"

      parameter name: "organisation_ids[]", in: :query, schema: { type: :array, items: { type: :string } }, description: "ID des organisations", example: "[1, 2]"
      parameter name: "user_id", in: :query, type: :integer, description: "ID de l'utilisateur", example: 12

      let!(:territory) { create(:territory) }
      let!(:organisation1) { create(:organisation, territory: territory, verticale: "rdv_insertion") }
      let!(:organisation2) { create(:organisation, territory: territory, verticale: "rdv_insertion") }
      let!(:organisation3) { create(:organisation, territory: territory, verticale: "rdv_solidarites") }
      let!(:user) { create(:user) }
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation1, organisation2]) }
      let!(:shared_secret) { "S3cr3T" }
      let!(:auth_headers) { api_auth_headers_with_shared_secret(agent, shared_secret) }
      let!(:uid) { auth_headers["uid"].to_s }
      let!(:"X-Agent-Auth-Signature") { auth_headers["X-Agent-Auth-Signature"].to_s }

      before do
        allow(Agent).to receive(:find_by).and_return(agent)
        allow(ENV).to receive(:fetch).with("SHARED_SECRET_FOR_AGENTS_AUTH").and_return(shared_secret)
        allow(ActiveSupport::SecurityUtils).to receive(:secure_compare).and_return(true)
      end

      response 200, "Ajouter un utilisateur à une ou plusieurs organisations" do
        let(:"organisation_ids[]") { [organisation1.id, organisation2.id, organisation3.id] }
        let(:user_id) { user.id }

        let!(:user_profile_count_before) { UserProfile.count }

        run_test!

        it { expect(UserProfile.count).to eq(user_profile_count_before + 2) } # organisation3 is not in the same territory
        it { expect(user.reload.organisations).to include(organisation1) }
        it { expect(user.reload.organisations).to include(organisation2) }
        it { expect(user.reload.organisations).not_to include(organisation3) }

        it "logs the API call" do
          expect(ApiCall.first.attributes.symbolize_keys).to include(
            controller_name: "user_profiles",
            action_name: "create_many",
            agent_id: agent.id
          )
        end
      end

      it_behaves_like "an endpoint that returns 401 - unauthorized" do
        let(:"organisation_ids[]") { [organisation1.id, organisation2.id, organisation3.id] }
        let(:user_id) { user.id }

        before do
          allow(ActiveSupport::SecurityUtils).to receive(:secure_compare).and_return(false)
        end
      end

      it_behaves_like "an endpoint that returns 404 - not found", "l'utilisateur n'a pas été trouvé" do
        let(:"organisation_ids[]") { [organisation1.id, organisation2.id, organisation3.id] }
        let(:user_id) { User.last.id + 1 }
      end
    end
  end
end
