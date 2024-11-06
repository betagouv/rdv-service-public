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
  end

  path "/api/accounts" do
    post "Créer un compte pour un agent" do
      description "Permet de créer un compte et une organisation pour un agent. Si le compte ou l'organisation existe déjà, il sera réutilisé"

      parameter name: :params, in: :query, schema: {
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
              address: { type: :string },
              external_id: { type: :string },
            },
          },
        },
        required: ["agent"],
      }

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
              name: "France Service 19e",
              address: "21 rue des Ardennes, Paris, 75019",
            },
          }
        end
      end
    end
  end
end
