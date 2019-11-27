RSpec.describe Agents::UsersController, type: :controller do
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

  describe "POST #create" do
    subject { post :create, params: { organisation_id: organisation_id, user: attributes } }

    context "for user without email" do
      let(:attributes) do
        {
          first_name: "Michel",
          last_name: "Lapin",
        }
      end

      it { expect { subject }.to change(User, :count).by(1) }

      it "redirects to the created user" do
        subject
        expect(response).to redirect_to(organisation_user_path(organisation_id, User.last.id))
      end
    end

    context "for user with already existing email" do
      let!(:user) { create(:user) }

      let(:attributes) do
        {
          first_name: "Michel",
          last_name: "Lapin",
          email: user.email,
        }
      end

      it { expect { subject }.not_to change(User, :count) }
      it { expect(subject).to render_template(:compare) }

      it do
        subject
        expect(assigns(:user_to_compare)).to eq(user)
      end
    end

    context "with invalid params" do
      let!(:user) { create(:user, email: nil, created_or_updated_by_agent: true) }

      let(:attributes) do
        {
          first_name: "Michel",
        }
      end

      it { expect { subject }.not_to change(User, :count) }
      it { expect(subject).to render_template(:new) }

      it do
        subject
        expect(assigns(:user_to_compare)).to be_nil
      end
    end
  end
end
