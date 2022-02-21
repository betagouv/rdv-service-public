# frozen_string_literal: true

describe Admin::Territories::SmsConfigurationsController, type: :controller do
  let(:territory) { create(:territory, departement_number: "62") }
  let(:organisation) { create(:organisation, territory: territory) }
  let(:agent) { create(:agent, organisations: [organisation]) }

  before do
    sign_in agent
  end

  describe "#show" do
    it "respond success" do
      get :show, params: { territory_id: territory.id }
      expect(response).to be_successful
    end
  end

  describe "#edit" do
    it "respond success if departement allowed" do
      territory.has_own_sms_provider = true
      territory.save!
      get :edit, params: { territory_id: territory.id }
      expect(response).to be_successful
    end

    it "redirected if departement not allowed" do
      territory = create(:territory, has_own_sms_provider: false)
      get :edit, params: { territory_id: territory.id }
      expect(response).to redirect_to(admin_territory_sms_configuration_path)
    end
  end

  describe "#update" do
    it "redirect to show" do
      get :update, params: { territory_id: territory.id, territory: { sms_provider: "netsize" } }
      expect(response).to redirect_to(admin_territory_sms_configuration_path)
    end
  end
end
