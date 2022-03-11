# frozen_string_literal: true

describe Admin::Territories::NotificationSettingsController, type: :controller do
  describe "#edit" do
    it "respond success" do
      territory = create(:territory)
      agent = create(:agent, role_in_territories: [territory], organisations: [create(:organisation, territory: territory)])
      sign_in agent
      get :edit, params: { territory_id: territory.id }
      expect(response).to be_successful
    end
  end

  describe "#update" do
    it "respond redirect to edit" do
      territory = create(:territory, show_rdv_motif: 1)
      agent = create(:agent, role_in_territories: [territory], organisations: [create(:organisation, territory: territory)])
      sign_in agent
      post :update, params: { territory_id: territory.id, territory: { show_rdv_motif: 0 } }
      expect(response).to redirect_to(edit_admin_territory_notification_settings_path(territory))
    end

    it "update territory" do
      territory = create(:territory, show_rdv_motif: 1)
      agent = create(:agent, role_in_territories: [territory], organisations: [create(:organisation, territory: territory)])
      sign_in agent
      expect do
        post :update, params: { territory_id: territory.id, territory: { show_rdv_motif: 0 } }
      end.to change { territory.reload.show_rdv_motif }.from(true).to(false)
    end
  end
end
