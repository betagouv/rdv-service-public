require "swagger_helper"

RSpec.describe "Api de création de comptes", swagger_doc: "accounts_api.json" do
  stub_env_with(COOP_MEDIATION_NUMERIQUE: "conum-api-test-key-123456")

  let(:auth_header) do
    { "X-COOP-MEDIATION-NUMERIQUE-API-KEY": "conum-api-test-key-123456" }
  end

  before do
    create(:territory, :conseillers_numeriques)
    create(:service, :conseiller_numerique)

    stub_request(
      :get,
      "https://api-adresse.data.gouv.fr/search/?postcode=75019&q=21%20rue%20des%20Ardennes,%20Paris,%2075019"
    ).to_return(status: 200, body: file_fixture("geocode_result.json").read, headers: {})
    stub_request(
      :get,
      "https://api-adresse.data.gouv.fr/search/?postcode=75007&q=20%20avenue%20de%20S%C3%A9gur,%20Paris,%2075007"
    ).to_return(status: 200, body: file_fixture("geocode_result.json").read, headers: {})
  end

  path "/api/accounts" do
    post "Créer un compte pour un agent" do
      description "Permet de créer un compte et une organisation pour un agent. Si le compte ou l'organisation existe déjà, il sera réutilisé"

      parameter(
        name: :params, # ce nom n'est pas utilisé, car tous les paramètres sont dans le body de la requête
        in: :body,
        schema: {
          type: :object,
          properties: {
            agent: {
              type: :object, properties: {
                email: { type: :string },
                first_name: { type: :string },
                last_name: { type: :string },
                external_id: { type: :string },
              },
            },
            organisation: {
              type: :object, properties: {
                name: { type: :string },
                external_id: { type: :string },
              },
            },
            lieux: {
              type: :array,
            },
          },
          required: ["agent"],
        },
        example: {
          agent: {
            email: "francis.factice@france-service.fr",
            first_name: "Francis",
            last_name: "Factice",
            external_id: "123456",
          },
          organisation: {
            external_id: "345678",
            name: "France Service 19e",
          },
          lieux: [
            {
              name: "Bureaux PIX",
              address: "21 rue des Ardennes, Paris, 75019",
            },
            {
              name: "Dinum",
              address: "20 avenue de Ségur, Paris, 75007",
            },
          ],
        }
      )

      with_examples
      produces "application/json"
      consumes "application/json"
      stub_env_with(COOP_MEDIATION_NUMERIQUE: "coop-mediation-numerique-api-test-key-123456")
      let(:"X-COOP-MEDIATION-NUMERIQUE-API-KEY") { "coop-mediation-numerique-api-test-key-123456" }

      security [{ "X-COOP-MEDIATION-NUMERIQUE-API-KEY": [] }]
      parameter name: "X-COOP-MEDIATION-NUMERIQUE-API-KEY", in: :header, type: :string, description: "Clé d'API", example: "coop-mediation-numerique-api-test-key-123456", required: true

      response 201, "Crée le compte" do
        run_test!

        let(:params) do
          {
            agent: {
              email: "francis.factice@france-service.fr",
              first_name: "Francis",
              last_name: "Factice",
              external_id: "123456",
            },
            organisation: {
              external_id: "123456",
              name: "ANCT",
            },
            lieux: [
              {
                name: "Bureaux PIX",
                address: "21 rue des Ardennes, Paris, 75019",
              },
              {
                name: "Dinum",
                address: "20 avenue de Ségur, Paris, 75007",
              },
            ],
          }
        end
      end
    end
  end
end
