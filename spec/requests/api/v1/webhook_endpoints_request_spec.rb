# frozen_string_literal: true

require "swagger_helper"

describe "WebhookEndpoints API", swagger_doc: "v1/api.json" do
  with_examples

  path "api/v1/organisations/{organisation_id}/webhook_endpoints" do
    get "Lister les webhook_endpoints d'une organisation" do
      with_authentication
      with_pagination

      tags "WebhookEndpoint"
      produces "application/json"
      operationId "getWebhookEndpoints"
      description "Renvoie tous les webhook_endpoints d'une organisation accessibles à l'agent·e authentifié·e, de manière paginée"

      parameter name: :organisation_id, in: :path, type: :integer, description: "ID de l'organisation", example: 123
      parameter name: "target_url", in: :query, type: :string, description: "L'url de destination du webhook endpoint", example: "https://www.rdv-insertion.fr/rdvs_webhooks", required: false

      let(:auth_headers) { api_auth_headers_for_agent(agent) }
      let(:"access-token") { auth_headers["access-token"].to_s }
      let(:uid) { auth_headers["uid"].to_s }
      let(:client) { auth_headers["client"].to_s }

      let!(:organisation) { create(:organisation) }
      let(:organisation_id) { organisation.id }

      response 200, "Retourne des WebhookEndpoints" do
        let!(:webhook_endpoints) { create_list(:webhook_endpoint, 5, organisation: organisation) }
        let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

        schema "$ref" => "#/components/schemas/webhook_endpoints"

        run_test!

        it { expect(response).to be_paginated(current_page: 1, next_page: nil, prev_page: nil, total_count: 5, total_pages: 1) }

        it { expect(parsed_response_body[:webhook_endpoints]).to match(WebhookEndpointBlueprint.render_as_hash(webhook_endpoints)) }
      end

      response 200, "Retourne des WebhooksEndpoints, filtrés par target_url" do
        let!(:matching) do
          create(:webhook_endpoint, organisation: organisation, target_url: "https://www.rdv-insertion.fr/webhooks")
        end
        let!(:unmatching) do
          create(:webhook_endpoint, organisation: organisation, target_url: "https://www.some-site.fr/webhooks")
        end
        let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
        let(:target_url) { "https://www.rdv-insertion.fr/webhooks" }

        run_test!

        it { expect(parsed_response_body[:webhook_endpoints]).to match([WebhookEndpointBlueprint.render_as_hash(matching)]) }
      end

      response 200, "when there is no webhook_endpoints" do
        let(:agent) { create(:agent) }

        run_test!

        it { expect(parsed_response_body[:webhook_endpoints]).to eq([]) }
      end

      it_behaves_like "an endpoint that returns 401 - unauthorized" do
        let(:agent) { create(:agent) }
      end
    end

    post "Créer un webhook_endpoint" do
      with_authentication

      tags "WebhookEndpoint"
      produces "application/json"
      operationId "createWebhookEndpoint"
      description "Crée un webhook_endpoint et le renvoie"

      parameter name: "organisation_id", in: :path, type: :integer, description: "ID de l'organisation", example: 123
      parameter name: "target_url", in: :query, type: :string, description: "L'url de destination du webhook endpoint", example: "https://www.rdv-insertion.fr/rdv_solidarites_webhooks"
      parameter name: "secret", in: :query, type: :string, description: "Le secret partagé avec l'application de destination du webhook", example: "abc123", required: false
      parameter name: "subscriptions[]", in: :query, style: :form, explode: true, schema: { type: :array, items: { type: :string } },
                description: "Les modèles concernés par le webhook", example: %w[rdv user user_profile organisation motif lieu agent agent_role], required: false

      let!(:territory) { create(:territory) }
      let!(:organisation) { create(:organisation, territory: territory) }
      let(:organisation_id) { organisation.id }
      let(:agent) { create(:agent, role_in_territories: [territory], admin_role_in_organisations: [organisation]) }

      let(:auth_headers) { api_auth_headers_for_agent(agent) }
      let(:"access-token") { auth_headers["access-token"].to_s }
      let(:uid) { auth_headers["uid"].to_s }
      let(:client) { auth_headers["client"].to_s }

      let(:target_url) { "https://www.rdv-insertion.fr/rdv_solidarites_webhooks" }
      let(:secret) { "abc123" }
      let(:"subscriptions[]") { %w[rdv user user_profile organisation motif lieu agent agent_role] }

      response 200, "Crée et renvoie un webhook_endpoint" do
        let!(:webhook_endpoint_count_before) { WebhookEndpoint.count }
        let(:created_webhook_endpoint) { WebhookEndpoint.find(parsed_response_body["webhook_endpoint"]["id"]) }

        schema "$ref" => "#/components/schemas/webhook_endpoint_with_root"

        run_test!

        it { expect(WebhookEndpoint.count).to eq(webhook_endpoint_count_before + 1) }

        it { expect(created_webhook_endpoint.organisation).to match(organisation) }

        it { expect(created_webhook_endpoint.target_url).to eq(target_url) }

        it { expect(created_webhook_endpoint.secret).to eq(secret) }

        it { expect(created_webhook_endpoint.subscriptions).to match_array(%w[rdv user user_profile organisation motif lieu agent agent_role]) }
      end

      it_behaves_like "an endpoint that returns 401 - unauthorized"

      it_behaves_like "an endpoint that returns 422 - unprocessable_entity", "des paramètres sont manquants, mal formés ou impossibles", true do
        let(:target_url) { nil }
        let(:secret) { nil }
      end

      it_behaves_like "an endpoint that returns 422 - unprocessable_entity", "la liste des abonnements choisis contient une ou plusieurs valeurs incorrectes", true do
        let(:"subscriptions[]") { %w[test] }
      end
    end
  end

  path "api/v1/organisations/{organisation_id}/webhook_endpoints/{webhook_endpoint_id}" do
    patch "Mettre à jour un webhook_endpoint" do
      with_authentication

      tags "WebhookEndpoint"
      produces "application/json"
      operationId "updateWebhookEndpoint"
      description "Met à jour un webhook_endpoint"

      parameter name: :webhook_endpoint_id, in: :path, type: :integer, description: "ID du wehbook_endpoint", example: 123
      parameter name: :organisation_id, in: :path, type: :integer, description: "ID de l'organisation", example: 123
      parameter name: "target_url", in: :query, type: :string, description: "L'url de destination du webhook endpoint", example: "https://www.rdv-insertion.fr/rdv_solidarites_webhooks"
      parameter name: "secret", in: :query, type: :string, description: "Le secret partagé avec l'application de destination du webhook", example: "abc123", required: false
      parameter name: "subscriptions[]", in: :query, style: :form, explode: true, schema: { type: :array, items: { type: :string } },
                description: "Les modèles concernés par le webhook", example: %w[rdv user user_profile organisation motif lieu agent agent_role], required: false

      let!(:territory) { create(:territory) }
      let!(:organisation) { create(:organisation, territory: territory) }
      let(:organisation_id) { organisation.id }
      let!(:webhook_endpoint) { create(:webhook_endpoint, organisation: organisation) }
      let(:webhook_endpoint_id) { webhook_endpoint.id }
      let(:agent) { create(:agent, role_in_territories: [territory], admin_role_in_organisations: [organisation]) }

      let(:auth_headers) { api_auth_headers_for_agent(agent) }
      let(:"access-token") { auth_headers["access-token"].to_s }
      let(:uid) { auth_headers["uid"].to_s }
      let(:client) { auth_headers["client"].to_s }

      let(:target_url) { "https://www.rdv-insertion.fr/rdv_solidarites_webhooks" }
      let(:"subscriptions[]") { %w[rdv user user_profile organisation motif lieu agent agent_role] }
      let(:secret) { "abc123" }

      response 200, "Met à jour et renvoie un webhook_endpoint" do
        let(:other_organisation) { create(:organisation, territory: territory) }
        let(:organisation_id) { other_organisation.id }

        schema "$ref" => "#/components/schemas/webhook_endpoint_with_root"

        run_test!

        it { expect(webhook_endpoint.reload.organisation).to eq(other_organisation) }

        it { expect(webhook_endpoint.reload.target_url).to eq(target_url) }

        it { expect(webhook_endpoint.reload.secret).to eq(secret) }

        it { expect(webhook_endpoint.reload.subscriptions).to eq(%w[rdv user user_profile organisation motif lieu agent agent_role]) }
      end

      it_behaves_like "an endpoint that returns 401 - unauthorized"

      it_behaves_like "an endpoint that returns 422 - unprocessable_entity", "des paramètres sont manquants, mal formés ou impossibles", true do
        let(:target_url) { nil }
        let(:secret) { nil }
      end

      it_behaves_like "an endpoint that returns 422 - unprocessable_entity", "la liste des abonnements choisis contient une ou plusieurs valeurs incorrectes", true do
        let(:"subscriptions[]") { %w[test] }
      end
    end
  end
end
