require "swagger_helper"

RSpec.describe "User Profile authentified API" do
  path "/api/rdvinsertion/user_profiles/create_many" do
    post "Ajouter un utilisateur à une ou plusieurs organisations" do
      with_rdv_insertion_oauth_authentication

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
      let!(:user_organisation) { create(:organisation, territory: territory, verticale: "rdv_insertion") }
      let!(:user) { create(:user, organisations: [user_organisation]) }
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation1, organisation2]) }
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

      context "when authentication fails" do
        let(:"organisation_ids[]") { [organisation1.id, organisation2.id, organisation3.id] }
        let(:user_id) { user.id }

        it "returns a 401 unauthorized response" do
          post "/api/rdvinsertion/user_profiles/create_many", params: { "organisation_ids[]": [organisation1.id, organisation2.id, organisation3.id], user_id: user.id }

          expect(response).to have_http_status(:unauthorized)
        end
      end

      context "when user is not found" do
        let(:"organisation_ids[]") { [organisation1.id, organisation2.id, organisation3.id] }
        let(:user_id) { User.last.id + 1 }

        it "returns a 404 not found" do
          post "/api/rdvinsertion/user_profiles/create_many", params: { "organisation_ids[]": [organisation1.id, organisation2.id, organisation3.id], user_id: user_id }, headers: auth_headers

          expect(response).to have_http_status(:not_found)
          expect(response.body).to include("not_found")
        end
      end

      context "when the user does not belong to a territory of the agent" do
        let!(:other_territory_organisation) { create(:organisation, verticale: "rdv_insertion") }
        let!(:user_from_another_territory) { create(:user, organisations: [other_territory_organisation]) }

        it "returns a 404 not found and does not create the user profiles" do
          expect do
            post "/api/rdvinsertion/user_profiles/create_many", params: { "organisation_ids[]": [organisation1.id, organisation2.id], user_id: user_from_another_territory.id }, headers: auth_headers
          end.not_to change(UserProfile, :count)

          expect(response).to have_http_status(:not_found)
          expect(response.body).to include("not_found")
        end
      end
    end
  end
end
