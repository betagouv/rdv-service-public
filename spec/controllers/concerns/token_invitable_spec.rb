RSpec.describe TokenInvitable, type: :controller do
  controller(ApplicationController) do
    include TokenInvitable

    def fake_action
      render plain: "ok"
    end
  end

  let!(:token) { "some-token" }
  let!(:invitation) { instance_double(Invitation) }
  let!(:user) { create(:user) }
  let!(:now) { Time.zone.parse("2022-08-03 10:22:00") }

  before do
    travel_to(now)
    routes.draw { get "fake_action" => "anonymous#fake_action" }
  end

  describe "#store_invitation_in_session_and_redirect" do
    subject { get :fake_action, params: params }

    let!(:params) { { invitation_token: token, motif_category_short_name: "rsa_orientation" } }

    before do
      allow(Invitation).to receive(:new).with(params).and_return(invitation)
      allow(invitation).to receive(:user).and_return(user)
    end

    context "when no token is passed" do
      let!(:token) { nil }

      it "does not store the token in session" do
        subject
        expect(request.session[:invitation]).to be_nil
      end

      it "does not redirect to root path" do
        subject
        expect(response).to be_successful
        expect(response).not_to redirect_to(root_path)
      end
    end

    context "when an invalid user token is passed" do
      before do
        allow(invitation).to receive(:token_valid?).and_return(false)
      end

      it "does not store the token in session" do
        subject
        expect(request.session[:invitation]).to be_nil
      end

      it "redirects to root path with a message" do
        subject
        expect(response).to redirect_to(root_path)
        expect(flash[:error]).to eq("Votre invitation n'est pas valide.")
      end
    end

    context "when a valid user token is passed" do
      before do
        allow(invitation).to receive(:token_valid?).and_return(true)
      end

      it "stores the token in session" do
        subject
        expect(request.session[:invitation]).to eq(params.merge(expires_at: Time.zone.parse("2022-08-03 10:32:00")))
      end

      it "redirects to current path without the token" do
        subject
        expect(response).to redirect_to("/fake_action?motif_category_short_name=rsa_orientation")
      end

      context "when a user is already connected" do
        let!(:user) { create(:user) }

        before { sign_in user }

        context "when it is the user linked to the invitation" do
          before do
            allow(invitation).to receive(:user).and_return(user)
          end

          it "does stores the invitation in session and redirect" do
            subject
            expect(request.session[:invitation]).to eq(params.merge(expires_at: Time.zone.parse("2022-08-03 10:32:00")))
            expect(response).to redirect_to("/fake_action?motif_category_short_name=rsa_orientation")
          end
        end

        context "when it is another user" do
          let!(:other_user) { create(:user) }

          before do
            allow(invitation).to receive(:user).and_return(other_user)
          end

          it "redirects to root path with a message" do
            subject
            expect(response).to redirect_to(root_path)
            expect(flash[:error]).to eq("L’utilisateur connecté ne correspond pas à l’utilisateur invité. Déconnectez-vous et réessayez.")
          end
        end
      end
    end
  end

  describe "#sign_in_with_session_token" do
    subject { get :fake_action }

    let!(:attributes) do
      { invitation_token: token, motif_category_short_name: "rsa_orientation", expires_at: Time.zone.parse("2022-08-03 10:32:00") }
    end

    before do
      request.session[:invitation] = attributes
      allow(Invitation).to receive(:new).with(attributes).and_return(invitation)
      allow(invitation).to receive(:token_valid?).and_return(true)
      allow(invitation).to receive(:expired?).and_return(false)
      allow(invitation).to receive(:user).and_return(user)
      allow(invitation).to receive(:rdv)
    end

    it "connecte l'usager et indique le mode de connexion utilisé" do
      subject
      expect(response).to be_successful
      expect(assigns(:current_user)).to eq(user)
      expect(assigns(:current_user).signed_in_with_invitation_token?).to be(true)
    end

    context "when the token is invalid" do
      before do
        allow(invitation).to receive(:token_valid?).and_return(false)
      end

      it "deletes the invitation and redirects to root path with a message" do
        subject
        expect(request.session[:invitation]).to be_nil
        expect(response).to redirect_to(root_path)
        expect(flash[:error]).to eq("Votre invitation n'est pas valide.")
      end
    end

    context "when the session expired" do
      before do
        allow(invitation).to receive(:expired?).and_return(true)
      end

      it "deletes the invitation and redirects to root path with a message" do
        subject
        expect(request.session[:invitation]).to be_nil
        expect(response).to redirect_to(root_path)
        expect(flash[:error]).to eq("La session a expiré")
      end
    end

    context "when a user is logged in already" do
      before { sign_in user }

      context "when it is the invited user" do
        it "does not mark the user as only invited" do
          subject
          expect(response).to be_successful
          expect(assigns(:current_user)).to eq(user)
          expect(assigns(:current_user)).not_to(be_signed_in_with_invitation_token)
        end
      end

      context "when it is another user" do
        let!(:other_user) { create(:user) }

        before do
          allow(invitation).to receive(:user).and_return(other_user)
        end

        it "redirects to root path with a message" do
          subject
          expect(response).to redirect_to(root_path)
          expect(flash[:error]).to eq("L’utilisateur connecté ne correspond pas à l’utilisateur invité. Déconnectez-vous et réessayez.")
        end
      end
    end
  end
end
