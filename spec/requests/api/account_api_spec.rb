require "swagger_helper"

RSpec.describe "Api de création de comptes", swagger_doc: "accounts_api.json" do
  stub_env_with(COOP_MEDIATION_NUMERIQUE: "conum-api-test-key-123456")

  let(:auth_header) do
    { "X-COOP-MEDIATION-NUMERIQUE-API-KEY": "conum-api-test-key-123456" }
  end

  path "/api/accounts" do
    post "Créer un compte pour un agent" do
      description "Permet de créer un compte et une organisation pour un agent. Si le compte ou l'organisation existe déjà, il sera réutilisé"
      with_examples
      produces "application/json"
      stub_env_with(COOP_MEDIATION_NUMERIQUE: "coop-mediation-numerique-api-test-key-123456")
      let(:"X-COOP-MEDIATION-NUMERIQUE-API-KEY") { "coop-mediation-numerique-api-test-key-123456" }

      security [{ "X-COOP-MEDIATION-NUMERIQUE-API-KEY": [] }]
      parameter name: "X-COOP-MEDIATION-NUMERIQUE-API-KEY", in: :header, type: :string, description: "Clé d'API", example: "coop-mediation-numerique-api-test-key-123456", required: true

      response 201, "Crée le compte" do
        run_test!

        let(:agent) do
          {
            email: "francis.factice@france-service.fr",
            first_name: "Francis",
            last_name: "Factice",
            external_id: "123456",
          }
        end
        let(:organisation) do
          {
            external_id: "123456",
            name: "France Service 19e",
            address: "21 rue des Ardennes, Paris, 75019",
          }
        end
      end
    end
  end
end
