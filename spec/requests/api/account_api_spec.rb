require "swagger_helper"

RSpec.describe "Api de création de comptes", swagger_doc: "accounts_api.json" do
  stub_env_with(CONUM: "conum-api-test-key-123456")

  let(:auth_header) do
    { "X-CONUM-API-KEY": "conum-api-test-key-123456" }
  end

  path "/api/accounts" do
    post "Créer un compte pour un agent" do
      description "Permet de créer un compte et une organisation pour un agent. Si le compte ou l'organisation existe déjà, il sera réutilisé"
      parameter name: "agent", type: :object, properties: {
        email: { type: :string },
        first_name: { type: :string },
        last_name: { type: :string },
        external_id: { type: :string },
      }, required: true
      parameter name: "organisation", type: :object, properties: {
        name: { type: :string },
        address: { type: :string },
        external_id: { type: :string },
      }, required: true

      with_examples
      produces "application/json"
      stub_env_with(CONUM_API_KEY: "conum-api-test-key-123456")
      let(:"X-CONUM-API-KEY") { "conum-api-test-key-123456" }

      security [{ "X-CONUM-API-KEY": [] }]
      parameter name: "X-CONUM-API-KEY", in: :header, type: :string, description: "Clé d'API", example: "conum-api-test-key-123456", required: true

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
