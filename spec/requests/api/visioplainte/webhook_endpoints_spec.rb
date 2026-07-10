# Cette spec vérifie les aspects de sécurité liés à ces endpoints d'api. Le comportement de l'api est documenté par des specs swagger.
RSpec.describe "Visioplainte Webhook Endpoints" do
  stub_env_with(DB_SEEDS_USERS_AND_AGENTS_PASSWORD: "Rdvservicepublictest1!")
  before { load Rails.root.join("db/seeds/visioplainte.rb") }

  include_context "Visioplainte Auth"

  let(:orga_gendarmerie) do
    Organisation.find_by(name: "Plateforme Visioplainte Gendarmerie") # créée dans les seeds
  end

  describe "#index" do
    let!(:visioplainte_webhook_endpoint) { create(:webhook_endpoint, organisation: orga_gendarmerie) }
    let!(:other_webhook_endpoint) { create(:webhook_endpoint) }

    it "doesn't include webhook endpoints of organisations from other territories" do
      get "/api/visioplainte/webhook_endpoints", headers: auth_header

      response_endpoints = response.parsed_body["webhook_endpoints"]

      expect(response_endpoints.count).to eq 1
      expect(response_endpoints.first["id"]).to eq visioplainte_webhook_endpoint.id
    end
  end

  describe "#create" do
    let!(:organisation) { create(:organisation) }

    it "doesn't allow injection an organisation_id param to create the endpoint for another organisation" do
      post "/api/visioplainte/webhook_endpoints", headers: auth_header, params: {
        organisation_id: organisation.id,
        target_url: "https://exemple.fr/webhook_rdv_service_public", subscriptions: [:rdv], secret: "fake_test_secret_123",
      }

      expect(orga_gendarmerie.webhook_endpoints.first.target_url).to eq "https://exemple.fr/webhook_rdv_service_public"
      expect(organisation.reload.webhook_endpoints).to be_blank
    end
  end

  describe "#update" do
    let!(:webhook_endpoint_from_other_organisation) { create(:webhook_endpoint, target_url: "https://exemple.fr") }

    it "doesn't allow using the id of an unrelated organisation's webhook endpoint" do
      expect do
        patch "/api/visioplainte/webhook_endpoints/#{webhook_endpoint_from_other_organisation.id}", headers: auth_header, params: { target_url: "https://new-url.fr" }
      end.to raise_error(ActiveRecord::RecordNotFound)

      expect(webhook_endpoint_from_other_organisation.reload.target_url).to eq "https://exemple.fr"
    end
  end

  describe "#delete" do
    let!(:webhook_endpoint_from_other_organisation) { create(:webhook_endpoint) }

    it "doesn't allow using the id of an unrelated organisation's webhook endpoint" do
      expect do
        delete "/api/visioplainte/webhook_endpoints/#{webhook_endpoint_from_other_organisation.id}", headers: auth_header
      end.to raise_error(ActiveRecord::RecordNotFound)

      expect(webhook_endpoint_from_other_organisation.reload).to be_present
    end
  end
end
