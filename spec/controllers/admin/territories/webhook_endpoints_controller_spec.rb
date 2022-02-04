# frozen_string_literal: true

describe Admin::Territories::WebhookEndpointsController, type: :controller do
  let(:territory) { create(:territory, departement_number: "62") }
  let(:organisation) { create(:organisation, territory: territory) }
  let(:agent) { create(:agent, admin_role_in_organisations: [organisation], role_in_territories: [territory]) }

  before do
    sign_in agent
  end

  describe "#index" do
    it "respond success" do
      get :index, params: { territory_id: territory.id }
      expect(response).to be_successful
    end

    it "assigns territory's webhooks" do
      webhook = create(:webhook_endpoint, organisation: organisation)
      get :index, params: { territory_id: territory.id }
      expect(assigns(:webhooks)).to eq([webhook])
    end
  end

  describe "#new" do
    it "respond success" do
      get :new, params: { territory_id: territory.id }
      expect(response).to be_successful
    end

    it "assigns territory's webhooks" do
      get :new, params: { territory_id: territory.id }
      expect(assigns(:webhook)).to be_kind_of(WebhookEndpoint)
    end
  end

  describe "#create" do
    context "when it's ok" do
      it "redirect to index" do
        post :create, params: { territory_id: territory.id, webhook_endpoint: { organisation_id: organisation.id, target_url: "https://example.com", secret: "XSECRETX" } }
        expect(response).to redirect_to(admin_territory_webhook_endpoints_path(territory))
      end

      it "create a new webhook endpoint" do
        expect do
          post :create, params: { territory_id: territory.id, webhook_endpoint: { organisation_id: organisation.id, target_url: "https://example.com", secret: "XSECRETX" } }
        end.to change(WebhookEndpoint, :count).from(0).to(1)
      end
    end

    context "with an error" do
      it "render new" do
        post :create, params: { territory_id: territory.id, webhook_endpoint: { organisation_id: organisation.id, target_url: "https://example.com", secret: nil } }
        expect(response).to render_template(:new)
      end

      it "assigns webhook" do
        post :create, params: { territory_id: territory.id, webhook_endpoint: { organisation_id: organisation.id, target_url: "https://example.com", secret: nil } }
        expect(assigns(:webhook)).to be_kind_of(WebhookEndpoint)
      end
    end
  end

  describe "#update" do
    context "when it's ok" do
      it "redirect to index" do
        webhook = create(:webhook_endpoint, organisation: organisation)
        post :update, params: { territory_id: territory.id, id: webhook.id, webhook_endpoint: { secret: "XSECRETX" } }
        expect(response).to redirect_to(admin_territory_webhook_endpoints_path(territory))
      end
    end

    context "with an error" do
      it "render new" do
        webhook = create(:webhook_endpoint, organisation: organisation)
        post :update, params: { territory_id: territory.id, id: webhook.id, webhook_endpoint: { secret: nil } }
        expect(response).to render_template(:new)
      end

      it "assigns webhook" do
        webhook = create(:webhook_endpoint, organisation: organisation)
        post :update, params: { territory_id: territory.id, id: webhook.id, webhook_endpoint: { secret: nil } }
        expect(assigns(:webhook)).to eq(WebhookEndpoint.first)
      end
    end
  end

  describe "#edit" do
    it "respond success" do
      webhook = create(:webhook_endpoint, organisation: organisation)
      get :edit, params: { territory_id: territory.id, id: webhook.id }
      expect(response).to be_successful
    end

    it "assigns territory's webhooks" do
      webhook = create(:webhook_endpoint, organisation: organisation)
      get :edit, params: { territory_id: territory.id, id: webhook.id }
      expect(assigns(:webhook)).to be_kind_of(WebhookEndpoint)
    end
  end

  describe "#destroy" do
    it "redirect to index" do
      webhook = create(:webhook_endpoint, organisation: organisation)
      post :destroy, params: { territory_id: territory.id, id: webhook }
      expect(response).to redirect_to(admin_territory_webhook_endpoints_path(territory))
    end

    it "destroy the webhook endpoint" do
      webhook = create(:webhook_endpoint, organisation: organisation)
      expect do
        post :destroy, params: { territory_id: territory.id, id: webhook }
      end.to change(WebhookEndpoint, :count).from(1).to(0)
    end
  end
end
