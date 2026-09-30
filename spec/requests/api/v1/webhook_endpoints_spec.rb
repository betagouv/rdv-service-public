RSpec.describe "WebhookEndpoints API" do
  let(:territory) { create(:territory) }
  let(:organisation) { create(:organisation, territory:) }
  let(:agent) { create(:agent, role_in_territories: [territory], admin_role_in_organisations: [organisation]) }
  let(:oauth_token) { create(:access_token, resource_owner_id: agent.id, application: create(:oauth_application)) }

  describe "#create avec un domaine non autorisé" do
    stub_env_with(ALLOWED_WEBHOOK_HOSTS: "rdvi.gouv.fr")

    it "refuse la création" do
      post "/api/v1/organisations/#{organisation.id}/webhook_endpoints", headers: oauth_client_headers(oauth_token), as: :json, params: {
        target_url: "https://exemple.fr/webhook_rdv_service_public", subscriptions: [:rdv], secret: "fake_test_secret_123",
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(parsed_response_body["error_messages"]).to eq(["target_url « exemple.fr » ne fait pas partie des domaines autorisés pour les webhooks. Contactez-nous pour ajouter votre domaine."])
      expect(organisation.reload.webhook_endpoints).to be_blank
    end
  end
end
