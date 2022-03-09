# frozen_string_literal: true

describe TokenInvitable, type: :controller do
  controller(ApplicationController) do
    include TokenInvitable

    def fake_action
      render plain: "ok"
    end
  end

  subject { get :fake_action, params: { invitation_token: token } }

  before do
    routes.draw { get "fake_action" => "anonymous#fake_action" }
  end

  context "when no token is passed" do
    let!(:token) { nil }

    it "does not assign an invited user" do
      subject
      expect(assigns(:user_by_token)).to be_nil
    end

    it "does not redirect to root path" do
      subject
      expect(response).to be_successful
      expect(response).not_to redirect_to(root_path)
    end
  end

  context "when an invalid user token is passed" do
    let!(:token) { "some-random-token" }

    it "does not assign an invited user" do
      subject
      expect(assigns(:user_by_token)).to be_nil
    end

    it "redirects to root path with a message" do
      subject
      expect(response).to redirect_to(root_path)
      expect(flash[:error]).to eq("Votre invitation n'est pas valide.")
    end
  end

  context "when a valid user token is passed" do
    let!(:user) { create(:user) }
    let!(:token) do
      user.invite! { |u| u.skip_invitation = true }
      user.raw_invitation_token
    end

    it "assigns the user" do
      subject
      expect(assigns(:user_by_token)).to eq(user)
    end

    it "does not redirect to root path" do
      subject
      expect(response).to be_successful
      expect(response).not_to redirect_to(root_path)
    end

    it "signs in the invited user" do
      subject
      expect(assigns(:current_user)).to eq(user)
    end

    it "marks the user as only invited" do
      subject
      expect(assigns(:current_user).only_invited?).to eq(true)
    end

    context "when the user is already connected" do
      before { sign_in user }

      it "does not mark the user as only invited" do
        subject
        expect(assigns(:current_user).only_invited?).to eq(false)
      end

      it "does not redirect to root path" do
        subject
        expect(response).to be_successful
        expect(response).not_to redirect_to(root_path)
      end
    end

    context "when another user is already connected" do
      let!(:another_user) { create(:user) }

      before { sign_in another_user }

      it "redirects to root path with a message" do
        subject
        expect(response).to redirect_to(root_path)
        expect(flash[:error]).to eq("L’utilisateur connecté ne correspond pas à l’utilisateur invité. Déconnectez-vous et réessayez.")
      end

      it "does not mark the user as only invited" do
        subject
        expect(assigns(:current_user).only_invited?).to eq(false)
      end
    end
  end

  context "when a rdv user token is passed" do
    let!(:user) { create(:user) }
    let!(:rdv) { create(:rdv) }
    let!(:rdv_user) { create(:rdvs_user, rdv: rdv, user: user) }

    let!(:another_rdv) { create(:rdv, users: [user]) }

    let!(:token) do
      rdv_user.invite! { |rdv_u| rdv_u.skip_invitation = true }
      rdv_user.raw_invitation_token
    end

    it "does not assign the user directly" do
      subject
      expect(assigns(:user_by_token)).to be_nil
    end

    it "assigns the rdv user" do
      subject
      expect(assigns(:rdv_user_by_token)).to eq(rdv_user)
    end

    it "signs in the user" do
      subject
      expect(assigns(:current_user)).to eq(user)
    end

    it "marks the user as only invited" do
      subject
      expect(assigns(:current_user).only_invited?).to eq(true)
    end

    it "marks the user as invited only for the rdv linked to token" do
      subject
      expect(assigns(:current_user).invited_for_rdv?(rdv)).to eq(true)
      expect(assigns(:current_user).invited_for_rdv?(another_rdv)).to eq(false)
    end
  end
end
