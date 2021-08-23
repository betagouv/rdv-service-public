# frozen_string_literal: true

RSpec.describe Admin::Territories::WebhookEndpointsController, type: :controller do
  let(:territory) { create(:territory, departement_number: "62") }
  let(:organisation) { create(:organisation, territory: territory) }
  let(:agent) { create(:agent, organisations: [organisation]) }

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
end
