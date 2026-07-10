require "swagger_helper"

RSpec.describe "Visioplainte API", swagger_doc: "visioplainte/api.json" do
  stub_env_with(DB_SEEDS_USERS_AND_AGENTS_PASSWORD: "Rdvservicepublictest1!")

  before do
    load Rails.root.join("db/seeds/visioplainte.rb")
  end

  let(:orga_gendarmerie) do
    Organisation.find_by(name: "Plateforme Visioplainte Gendarmerie") # créée dans les seeds
  end

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
      parameter name: "target_url", in: :query, type: :string, description: "L'url à appeler pour notifier d'une mise à jour"
      parameter name: "secret", in: :query, type: :string, description: "Le secret qui servira à signer les appels"
      parameter name: "subscriptions[]", in: :query, type: :array,
                description: "Le type de mises à jours pour lesquelles les notifications seront envoyées. Les valeurs possibles  à envoyer dans le tableau sont #{WebhookEndpoint::ALL_SUBSCRIPTIONS}"

      response 201, "Crée l'endpoint de webhook" do
        run_test!
        schema({
                 type: :object,
                 properties: {
                   id: { type: :integer },
                   target_url: { type: :string },
                   organisation_id: { type: :integer },
                   subscriptions: { type: :array },
                 },
                 required: WebhookEndpointBlueprint.reflections[:default].fields.keys,
               })

        let(:target_url) { "https://exemple.fr/webhook_rdv_service_public" }
        let(:"subscriptions[]") { ["rdv"] } # rubocop:disable Rspec/VariableName
        let(:secret) { "fake_test_secret_123" }

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
end
