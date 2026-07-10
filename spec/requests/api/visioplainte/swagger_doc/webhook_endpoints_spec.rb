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
  end
end
