RSpec.describe Organisations::UsersController, type: :controller do
  render_views

  let(:agent) { create(:agent) }
  let(:organisation_id) { agent.organisation_ids.first }
  let!(:user) { create(:user) }

  before do
    sign_in agent
  end

  describe "DELETE destroy" do
    it "removes user from organisation" do
      expect do
        delete :destroy, params: { organisation_id: organisation_id, id: user.id }
        user.reload
      end.to change(user, :organisation_ids).from([organisation_id]).to([])
    end

    it "does not destroy user" do
      expect do
        delete :destroy, params: { organisation_id: organisation_id, id: user.id }
      end.not_to change(User, :count)
    end
  end
end
