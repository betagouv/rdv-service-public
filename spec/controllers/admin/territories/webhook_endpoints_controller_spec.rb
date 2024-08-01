RSpec.describe Admin::Territories::WebhookEndpointsController, type: :controller do
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

    context "when trying to view the list of webhook endpoints in a territory for which i can only manage teams" do
      render_views
      let(:other_territory) { create(:territory) }
      let(:other_organisation) { create(:organisation, territory: other_territory) }
      let!(:other_webhook) { create(:webhook_endpoint, organisation: other_organisation, target_url: "https://www.exemple.fr") }

      before do
        create(:agent_territorial_access_right, agent: agent, territory: other_territory, allow_to_manage_teams: true)
      end

      it "doesn't show the webhook_endpoints" do
        get :index, params: { territory_id: other_territory.id }
        expect(response.body).not_to include("https://www.exemple.fr")
      end
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

    context "creating a webhook on an organisation that does not belong to the agent’s territory" do
      let!(:other_orga) { create(:organisation, territory: create(:territory)) }

      it "returns an error and does not create the endpoint" do
        post :create, params: { territory_id: territory.id, webhook_endpoint: { organisation_id: other_orga.id, target_url: "https://example.com", secret: "XSECRETX" } }
        expect(other_orga.webhook_endpoints.count).to eq(0)
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

      it "doens't update the secret if it doesn't change" do
        webhook = create(:webhook_endpoint, organisation: organisation, secret: "123456789")
        post :update, params: { territory_id: territory.id, id: webhook.id, webhook_endpoint: { secret: "******789" } }
        expect(WebhookEndpoint.first.secret).to eq(webhook.secret)
      end

      it "update the secret if it change" do
        webhook = create(:webhook_endpoint, organisation: organisation, secret: "123456789")
        post :update, params: { territory_id: territory.id, id: webhook.id, webhook_endpoint: { secret: "987654321" } }
        expect(WebhookEndpoint.first.secret).to eq("987654321")
      end

      it "update the target_url" do
        webhook = create(:webhook_endpoint, organisation: organisation, target_url: "https://example.com", secret: "123")
        post :update, params: { territory_id: territory.id, id: webhook.id, webhook_endpoint: { target_url: "https://example.org" } }
        expect(WebhookEndpoint.first.target_url).to eq("https://example.org")
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
