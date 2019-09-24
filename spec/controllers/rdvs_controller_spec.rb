RSpec.describe Pros::RdvsController, type: :controller do
  describe "DELETE destroy" do
    let(:pro) { create(:pro) }
    let(:rdv) { create(:rdv) }

    before do
      sign_in pro
    end

    it "cancel rdv" do
      delete :destroy, params: { id: rdv.id }
      expect(rdv.reload.cancelled?).to be true
    end
  end
end
