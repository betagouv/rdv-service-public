# frozen_string_literal: true

describe Admin::Territories::MotifFieldsController, type: :controller do
  describe "#edit" do
    it "responds success" do
      territory = create(:territory)
      agent = create(:agent, role_in_territories: [territory])
      sign_in agent
      get :edit, params: { territory_id: territory.id }
      expect(response).to be_successful
    end
  end
end
