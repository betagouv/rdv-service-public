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
      parameter name: "logement", in: :query, type: :string, enum: %w[sdf heberge en_accession_propriete proprietaire autre locataire], description: "Type de logement de l'utilisateur",
                example: "proprietaire", required: false
      parameter name: "notes", in: :query, type: :string, description: "Une note sur le profil utilisateur", example: "Super note", required: false

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
        let(:logement) { "sdf" }
        let(:notes) { "Super Note" }

        let!(:user_profile_count_before) { UserProfile.count }
        let(:created_user_profile) do
          UserProfile.find_by(user_id: parsed_response_body.dig("user_profile", "user", "id"), organisation_id: parsed_response_body.dig("user_profile", "organisation", "id"))
        end

        schema "$ref" => "#/components/schemas/user_profile_with_root"

        run_test!

        it { expect(UserProfile.count).to eq(user_profile_count_before + 1) }

        it { expect(created_user_profile.organisation).to eq(organisation) }

        it { expect(created_user_profile.user).to eq(user) }

        it { expect(created_user_profile.logement).to eq("sdf") }

        it { expect(created_user_profile.notes).to eq("Super Note") }
      end

      response 403, "Impossible de créer un profil utilisateur quand on a pas accès à l'organisation" do
        let!(:unauthorized_orga) { create(:organisation) }
        let(:organisation_id) { unauthorized_orga.id }
        let(:user_id) { user.id }
        let(:logement) { "sdf" }
        let(:notes) { "Super Note" }

        let!(:user_profile_count_before) { UserProfile.count }

        schema "$ref" => "#/components/schemas/error_unauthorized"

        run_test!

        it { expect(UserProfile.count).to eq(user_profile_count_before) }
      end

      it_behaves_like "an authenticated endpoint" do
        let(:organisation_id) { organisation.id }
        let(:user_id) { user.id }
        let(:logement) { "sdf" }
        let(:notes) { "Super Note" }
      end

      response 403, "Impossible de créer un profil utilisateur quand l'organisation n'est pas connue", document: false do
        let(:organisation_id) { "inconnu" }
        let(:user_id) { user.id }
        let(:logement) { "sdf" }
        let(:notes) { "Super Note" }

        let!(:user_profile_count_before) { UserProfile.count }

        schema "$ref" => "#/components/schemas/error_unauthorized"

        run_test!

        it { expect(UserProfile.count).to eq(user_profile_count_before) }
      end

      response 422, "Renvoie 'unprocessable_entity' quand l'utilisateur ou l'organisation n'est pas connue ou quand le logement n'est pas parmi les choix possibles ou que ce profil existe déjà" do
        let(:organisation_id) { organisation.id }
        let(:user_id) { "inconnu" }
        let(:logement) { "sdf" }
        let(:notes) { "Super Note" }

        let!(:user_profile_count_before) { UserProfile.count }

        schema "$ref" => "#/components/schemas/error_unprocessable_entity"

        run_test!

        it { expect(UserProfile.count).to eq(user_profile_count_before) }
      end

      response 422, "Renvoie 'unprocessable_entity' quand le logement n'est pas parmi les choix possibles", document: false do
        let(:organisation_id) { organisation.id }
        let(:user_id) { user.id }
        let(:logement) { "inconnu" }
        let(:notes) { "Super Note" }

        let!(:user_profile_count_before) { UserProfile.count }

        schema "$ref" => "#/components/schemas/error_unprocessable_entity"

        run_test!

        it { expect(UserProfile.count).to eq(user_profile_count_before) }
      end

      response 422, "Renvoie 'unprocessable_entity' quand le user_profil existe déjà", document: false do
        let!(:existing_profile) { create(:user_profile, user: user, organisation: organisation) }
        let(:organisation_id) { organisation.id }
        let(:user_id) { user.id }
        let(:logement) { "sdf" }
        let(:notes) { "Super Note" }

        let!(:user_profile_count_before) { UserProfile.count }

        schema "$ref" => "#/components/schemas/error_unprocessable_entity"

        run_test!

        it { expect(UserProfile.count).to eq(user_profile_count_before) }
      end
    end
  end
end
