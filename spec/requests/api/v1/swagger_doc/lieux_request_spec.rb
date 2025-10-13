require "swagger_helper"

RSpec.describe "API des lieux", swagger_doc: "v1/api.json" do
  with_examples

  path "/api/v1/lieux" do
    get "Lister les lieux" do
      with_oauth_token_authentication
      with_pagination

      tags "Lieux"
      produces "application/json"
      operationId "listLieux"
      description "Liste tous les lieux accessibles par l’agent connecté. N’inclut pas les lieux ponctuels ni les lieux désactivés."

      let!(:organisation) { create(:organisation) }
      let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
      let(:oauth_token) { create(:access_token, resource_owner_id: agent.id) }
      let(:authorization) { "Bearer #{oauth_token.plaintext_token}" }

      response 200, "Renvoie une liste des lieux" do
        schema "$ref" => "#/components/schemas/lieux"

        run_test!
      end
    end

    post "Créer un lieu" do
      with_oauth_token_authentication

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
      parameter name: "external_reference", in: :query, schema: {
        type: :object,
        properties: { external_reference: {
          type: :object,
          properties: { external_id: { type: :string } },
        } },
      }, description: "L'id du lieu dans votre système pour éviter la création de doublons", required: false

      let!(:organisation) { create(:organisation) }
      let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
      let(:oauth_token) { create(:access_token, resource_owner_id: agent.id) }
      let(:authorization) { "Bearer #{oauth_token.plaintext_token}" }

      response 200, "Crée et renvoie un lieu" do
        let(:organisation_id) { organisation.id }
        let(:latitude) { 44.5569244 }
        let(:longitude) { 4.7521632 }
        let(:name) { "Maison France Service de Montreuil" }
        let(:address) { "77 avenue de Ségur, 75015 Paris" }
        let(:phone_number) { "01 22 33 44 55" }
        let(:external_reference) do
          {
            external_reference: { external_id: "123ABC" },
          }
        end

        schema "$ref" => "#/components/schemas/lieu"

        run_test!

        specify do
          expect(Lieu.last).to have_attributes(
            address:, name:, latitude:, longitude:, organisation_id:, phone_number:
          )

          expect(Lieu.last.external_references.last).to have_attributes(
            external_id: "123ABC", territory_id: organisation.territory_id
          )
        end
      end
    end
  end
end
