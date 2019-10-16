RSpec.describe Agents::RdvsController, type: :controller do
  describe "DELETE destroy" do
    let(:agent) { create(:agent) }
    let(:rdv) { create(:rdv) }

    before do
      sign_in agent
    end

    it "cancel rdv" do
      delete :destroy, params: { id: rdv.id }
      expect(rdv.reload.cancelled?).to be true
    end
  end
end
