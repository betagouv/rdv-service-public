RSpec.describe "Edit territory", type: :request do
  include Rails.application.routes.url_helpers

  let(:territory) { create(:territory) }
  let(:agent) { create(:agent, role_in_territories: [territory]) }

  before { sign_in agent }

  describe "GET /admin/territories/3/edit" do
    it "is successful" do
      get edit_admin_territory_path(territory)
      expect(response).to be_successful
    end
  end

  describe "PUT /admin/territories/3" do
    it "is redirect to edit" do
      put admin_territory_path(territory), params: { territory: { phone_number: "0101010101" } }
      expect(response).to redirect_to(edit_admin_territory_path(territory))
    end

    it "update territory" do
      put admin_territory_path(territory), params: { territory: { phone_number: "0101010101" } }
      expect(territory.reload.phone_number).to eq("0101010101")
    end
  end
end
