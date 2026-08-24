require "swagger_helper"

RSpec.describe "Visioplainte API", swagger_doc: "visioplainte/api.json" do
  stub_env_with(DB_SEEDS_USERS_AND_AGENTS_PASSWORD: "Rdvservicepublictest1!")

  before do
    load Rails.root.join("db/seeds/visioplainte.rb")
  end

  let(:orga_gendarmerie) do
    Organisation.find_by(name: "Plateforme Visioplainte Gendarmerie") # créée dans les seeds
  end

  def self.document_schema
    schema({
             type: :object,
             properties: {
               id: { type: :integer },
               target_url: { type: :string },
               organisation_id: { type: :integer },
               subscriptions: { type: :array, items: { type: "string" } },
             },
             required: WebhookEndpointBlueprint.reflections[:default].fields.keys,
           })
  end

  example_params = {
    target_url: "https://exemple.fr/webhook_rdv_service_public",
    subscriptions: ["rdv"],
    secret: "fake_test_secret_123",
  }

  path "/api/visioplainte/webhook_endpoints" do
    get "Lister les endpoints de webhooks" do
      with_visioplainte_authentication

      tags "WebhookEndpoint"
      description "Liste tous les endpoints de webhooks de l'espace Visioplainte"

      let!(:webhook_endpoint) do
        create(:webhook_endpoint, organisation: orga_gendarmerie, target_url: "https://exemple.fr/webhook_rdv_service_public", subscriptions: [:rdv])
      end

      response 200, "Renvoie la liste" do
        run_test!

        specify do
          expect(parsed_response_body).to eq(
            {
              "webhook_endpoints" =>
                        [{
                          "id" => webhook_endpoint.id,
                          "organisation_id" => orga_gendarmerie.id,
                          "subscriptions" => ["rdv"],
                          "target_url" => "https://exemple.fr/webhook_rdv_service_public",
                        }],
            }
          )
        end
      end
    end

    post "Créer un endpoint de webhook" do
      with_visioplainte_authentication

      tags "WebhookEndpoint"
      description "Crée un endpoint de webhook dans l'espace Visioplainte"

      parameter(name: "webhook_endpoint_attributes", in: :body, description: "Les attributs du webhook endpoint à créer", type: :object, schema: {
                  example: example_params,
                  properties: {
                    target_url: { type: :string, required: true, description: "L'url à appeler pour notifier d'une mise à jour" },
                    secret: { type: :string, required: true, description: "Le secret qui servira à signer les appels" },
                    subscriptions: { type: :array, required: true,
                                     items: { type: "string",
                                              description: "Le type de mises à jours pour lesquelles les notifications seront envoyées. Les valeurs possibles  à envoyer dans le tableau sont #{WebhookEndpoint::ALL_SUBSCRIPTIONS}. Typiquement c'est la valeur rdv qui sera la plus utile.", }, }, # rubocop:disable Layout/LineLength
                  },
                })

      response 201, "Crée l'endpoint de webhook" do
        run_test!
        document_schema
        let(:webhook_endpoint_attributes) { example_params }

        specify do
          expect(WebhookEndpoint.last).to have_attributes(
            organisation: orga_gendarmerie,
            target_url: "https://exemple.fr/webhook_rdv_service_public",
            secret: "fake_test_secret_123",
            subscriptions: ["rdv"]
          )
        end
      end
    end
  end

  path "/api/visioplainte/webhook_endpoints/{id}" do
    patch "Modifier un endpoint de webhook" do
      with_visioplainte_authentication

      tags "WebhookEndpoint"
      description "Crée un endpoint de webhook dans l'espace Visioplainte, typiquement pour faire une rotation de secret"

      parameter name: "id", in: :path, type: :integer, description: "L'id de l'endpoint de webhook à modifier"

      parameter(name: "webhook_endpoint_attributes", in: :body, description: "Les attributs du webhook endpoint à créer", type: :object, schema: {
                  example: example_params,
                  properties: {
                    target_url: { type: :string, required: false, description: "L'url à appeler pour notifier d'une mise à jour" },
                    secret: { type: :string, required: false, description: "Le secret qui servira à signer les appels" },
                    subscriptions: { type: :array, required: false,
                                     items: { type: "string",
                                              description: "Le type de mises à jours pour lesquelles les notifications seront envoyées. Les valeurs possibles  à envoyer dans le tableau sont #{WebhookEndpoint::ALL_SUBSCRIPTIONS}. Typiquement c'est la valeur rdv qui sera la plus utile.", }, }, # rubocop:disable Layout/LineLength
                  },
                })

      response 200, "Modifie un endpoint de webhook" do
        run_test!
        document_schema
        let(:webhook_endpoint_attributes) do
          { secret: "new_fake_test_secret_456" }
        end

        let(:id) { webhook_endpoint.id }
        let!(:webhook_endpoint) do
          create(:webhook_endpoint, organisation: orga_gendarmerie, target_url: "https://exemple.fr/webhook_rdv_service_public", subscriptions: [:rdv])
        end

        specify do
          expect(webhook_endpoint.reload.secret).to eq "new_fake_test_secret_456"
        end
      end
    end

    delete "Supprimer un endpoint de webhook" do
      with_visioplainte_authentication

      tags "WebhookEndpoint"
      description "Supprime un endpoint de webhook dans l'espace Visioplainte"

      parameter name: "id", in: :path, type: :integer, description: "L'id de l'endpoint de webhook à supprimer"

      response 204, "Supprime un endpoint de webhook" do
        run_test!
        let(:id) { webhook_endpoint.id }
        let!(:webhook_endpoint) do
          create(:webhook_endpoint, organisation: orga_gendarmerie, target_url: "https://exemple.fr/webhook_rdv_service_public", subscriptions: [:rdv])
        end

        specify do
          expect(WebhookEndpoint.find_by(id: webhook_endpoint.id)).to be_blank
        end
      end
    end
  end
end
