require "swagger_helper"

RSpec.describe "API des lieux", swagger_doc: "v1/api.json" do
  with_examples

  path "/api/v1/lieux" do
    get "Lister les lieux" do
      with_oauth_token_authentication
      with_pagination

      tags "Lieux"
      operationId "listLieux"
      description "Liste tous les lieux accessibles par l’agent connecté. N’inclut pas les lieux ponctuels ni les lieux désactivés."

      let!(:organisation) { create(:organisation) }
      let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

      response 200, "Renvoie une liste des lieux" do
        schema "$ref" => "#/components/schemas/lieux"

        run_test!
      end
    end

    post "Créer un lieu" do
      with_oauth_token_authentication

      tags "Lieux"
      operationId "createLieu"
      description "Crée un lieu"

      parameter(
        name: :params,
        in: :body,
        schema: {
          type: :object,
          properties: {
            organisation_id: { type: :integer, description: "ID de l'organisation", example: 12 },
            name: { type: :string, description: "Le nom de l'organisation", example: "Maison France Service de Montreuil" },
            address: { type: :string, description: "L'adresse au format 123 Rue Exemple, 12345 Ville", example: "77 avenue de Ségur, 75015 Paris" },
            latitude: { type: :number, required: true, example: "48.8475271" },
            longitude: { type: :number, required: true, example: "2.3036545" },
            phone_number: { type: :string, description: "Numéro de téléphone", example: "33600008012", required: false },
            external_reference: { type: :object, schema: {
              type: :object,
              properties: { external_reference: {
                type: :object,
                properties: { external_id: { type: :string } },
              } },
            }, description: "L'id du lieu dans votre système pour éviter la création de doublons", required: false, },
          },
        }
      )

      let!(:organisation) { create(:organisation) }
      let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

      response 201, "Crée et renvoie un lieu" do
        let(:params) do
          {
            organisation_id: organisation.id,
            latitude: 44.5569244,
            longitude: 4.7521632,
            name: "Maison France Service de Montreuil",
            address: "77 avenue de Ségur, 75015 Paris",
            phone_number: "01 22 33 44 55",
            external_reference: { external_id: "123ABC" },
          }
        end
        schema "$ref" => "#/components/schemas/lieu"

        run_test!

        specify do
          expect(Lieu.last).to have_attributes(
            params.slice(:address, :name, :latitude, :longitude, :organisation_id, :phone_number)
          )

          expect(Lieu.last.external_references.last).to have_attributes(
            external_id: "123ABC", territory_id: organisation.territory_id
          )
        end
      end
    end
  end
end
