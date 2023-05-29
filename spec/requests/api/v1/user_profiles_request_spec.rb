# frozen_string_literal: true

require "swagger_helper"

describe "User Profile authentified API", swagger_doc: "v1/api.json" do
  with_examples

  path "/api/v1/user_profiles" do
    post "Créer un profil utilisateur" do
      with_authentication

      tags "UserProfile"
      produces "application/json"
      operationId "createUserProfile"
      description "Crée un profil utilisateur"

      parameter name: "organisation_id", in: :query, type: :integer, description: "ID de l'organisation", example: 12
      parameter name: "user_id", in: :query, type: :integer, description: "ID de l'utilisateur", example: 12

      let!(:territory) { create(:territory) }
      let!(:organisation) { create(:organisation, territory: territory) }
      let!(:user) { create(:user) }
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
      let(:auth_headers) { api_auth_headers_for_agent(agent) }
      let(:"access-token") { auth_headers["access-token"].to_s }
      let(:uid) { auth_headers["uid"].to_s }
      let(:client) { auth_headers["client"].to_s }

      response 200, "Crée et renvoie un profil utilisateur" do
        let(:organisation_id) { organisation.id }
        let(:user_id) { user.id }

        let!(:user_profile_count_before) { UserProfile.count }
        let(:created_user_profile) do
          UserProfile.find_by(user_id: parsed_response_body.dig("user_profile", "user", "id"), organisation_id: parsed_response_body.dig("user_profile", "organisation", "id"))
        end

        schema "$ref" => "#/components/schemas/user_profile_with_root"

        run_test!

        it { expect(UserProfile.count).to eq(user_profile_count_before + 1) }

        it { expect(created_user_profile.organisation).to eq(organisation) }

        it { expect(created_user_profile.user).to eq(user) }
      end

      it_behaves_like "an endpoint that returns 403 - forbidden", "l'agent·e n'a pas accès à l'organisation" do
        let!(:unauthorized_orga) { create(:organisation) }
        let(:organisation_id) { unauthorized_orga.id }
        let(:user_id) { user.id }
      end

      it_behaves_like "an endpoint that returns 401 - unauthorized" do
        let(:organisation_id) { organisation.id }
        let(:user_id) { user.id }
      end

      it_behaves_like "an endpoint that returns 422 - unprocessable_entity", "l'utilisateur ou l'organisation est inconnu(e) ou ce profil existe déjà", true do
        let(:organisation_id) { organisation.id }
        let(:user_id) { "inconnu" }
      end

      it_behaves_like "an endpoint that returns 422 - unprocessable_entity", "le user_profil existe déjà", false do
        let!(:existing_profile) { create(:user_profile, user: user, organisation: organisation) }
        let(:organisation_id) { organisation.id }
        let(:user_id) { user.id }
      end
    end

    delete "Détruit le profil utilisateur de l'organisation" do
      with_authentication

      tags "UserProfile"
      produces "application/json"
      operationId "deleteUserProfile"
      description "Détruit le profil utilisateur de l'organisation"

      parameter name: "organisation_id", in: :query, type: :integer, description: "ID de l'organisation", example: 14
      parameter name: "user_id", in: :query, type: :integer, description: "ID de l'utilisateur", example: 12

      let!(:organisation) { create(:organisation) }
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
      let!(:user) { create(:user, organisations: [organisation]) }
      let(:auth_headers) { api_auth_headers_for_agent(agent) }
      let(:"access-token") { auth_headers["access-token"].to_s }
      let(:uid) { auth_headers["uid"].to_s }
      let(:client) { auth_headers["client"].to_s }
      let!(:organisation_id) { organisation.id }
      let!(:user_id) { user.id }

      response 204, "détruit le profil utilisateur de l'organisation" do
        run_test!

        it { change(UserProfile, :count).by(-1) }
      end

      response 204, "détruit l'utilisateur s'il n'appartient qu'à une organisation" do
        run_test!

        it { expect { user.reload }.to raise_error(ActiveRecord::RecordNotFound) }
      end

      response 204, "ne détruit pas l'utilisateur s'il n'appartient à plusieurs organisations" do
        let!(:other_org) { create(:organisation) }
        let!(:user) { create(:user, organisations: [organisation, other_org]) }

        run_test!

        it { expect(user.reload).not_to be_destroyed }
      end

      it_behaves_like "an endpoint that returns 403 - forbidden", "l'agent n'appartient pas à l'organisation" do
        let!(:other_organisation) { create(:organisation) }
        let!(:agent) { create(:agent, basic_role_in_organisations: [other_organisation]) }
      end

      it_behaves_like "an endpoint that returns 401 - unauthorized"

      response 404, "le profil utilisateur n'existe pas" do
        let!(:organisation_id) { "inconnu" }

        run_test!
      end

      it_behaves_like "an endpoint that returns 422 - unprocessable_entity", "l'utilisateur a un rdv de prévu dans l'organisation", false do
        let!(:rdv) { create(:rdv, users: [user], organisation: organisation, starts_at: 2.days.from_now) }
      end
    end
  end
end
