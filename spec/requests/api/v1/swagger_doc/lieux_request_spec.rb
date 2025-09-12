require "swagger_helper"

RSpec.describe "API des lieux", swagger_doc: "v1/api.json" do
  with_examples

  path "/api/v1/lieux" do
    post "Créer un profil utilisateur" do
      with_authentication

      tags "Lieux"
      produces "application/json"
      operationId "createLieu"
      description "Crée un lieu"

      parameter name: "organisation_id", in: :query, type: :integer, description: "ID de l'organisation", example: 12
      parameter name: "name", in: :query, type: :string, description: "Le nom de l'organisation", example: "Maison France Service de Montreuil"
      parameter name: "address", in: :query, type: :string, description: "L'adresse au format 123 Rue Exemple, 12345 Ville", example: "77 avenue de Ségur, 75015 Paris"
      parameter name: "latitude", in: :query, type: :float
      parameter name: "longitude", in: :query, type: :float
      parameter name: "phone_number", in: :query, type: :string, description: "Numéro de téléphone", example: "33600008012", required: false

      let!(:organisation) { create(:organisation) }
      let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
      let(:auth_headers) { api_auth_headers_for_agent(agent) }
      let(:"access-token") { auth_headers["access-token"].to_s }
      let(:uid) { auth_headers["uid"].to_s }
      let(:client) { auth_headers["client"].to_s }

      response 200, "Crée et renvoie un lieu" do
        let(:organisation_id) { organisation.id }
        let(:latitude) { 44.5569244 }
        let(:longitude) { 4.7521632 }
        let(:name) { "Maison France Service de Montreuil" }
        let(:address) { "77 avenue de Ségur, 75015 Paris" }
        let(:phone_number) { "01 22 33 44 55" }

        schema "$ref" => "#/components/schemas/lieu"

        run_test!

        specify do
          expect(Lieu.last).to have_attributes(
            address:, name:, latitude:, longitude:, organisation_id:, phone_number:
          )
        end
      end
    end
  end
end
