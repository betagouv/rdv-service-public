RSpec.describe RestrictedAuthConcern do
  controller(ApplicationController) do
    include RestrictedAuthConcern # rubocop:disable RSpec/DescribedClass

    prepend_before_action do
      store_restricted_auth_token_in_session_and_redirect
    end

    def fake_action
      render plain: "ok"
    end

    def fake_action_not_using_invitation
      render plain: "ok"
    end
  end

  let!(:token) { "some-token" }
  let!(:user) { create(:user) }
  let!(:now) { Time.zone.parse("2022-08-03 10:22:00") }

  before do
    travel_to(now)
    routes.draw do
      get "fake_action" => "anonymous#fake_action"
      get "fake_action_not_using_invitation" => "anonymous#fake_action_not_using_invitation"
    end
  end

  describe "#store_restricted_auth_token_in_session_and_redirect" do
    subject { get :fake_action, params: params }

    let!(:params) { { invitation_token: token, motif_category_short_name: "rsa_orientation" } }

    context "when no token is passed" do
      let!(:token) { nil }

      it "does not store the token in session" do
        subject
        expect(request.session[:restricted_auth]).to be_nil
      end

      it "does not redirect to root path" do
        subject
        expect(response).to be_successful
        expect(response).not_to redirect_to(root_path)
      end
    end

    context "when an invalid user token is passed" do
      let!(:token) { "some-token" }

      it "does not store the token in session" do
        subject
        expect(request.session[:restricted_auth]).to be_nil
      end

      it "redirects to root path with a message" do
        subject
        expect(response).to redirect_to(root_path)
        expect(flash[:error]).to eq("Votre invitation n'est pas valide.")
      end
    end

    context "when a valid user token is passed" do
      let!(:token) { user.set_rdv_invitation_token! }

      it "stores the token and the invitation params in session" do
        subject
        expect(request.session[:restricted_auth]).to eq(invitation_token: token, expires_at: Time.zone.parse("2022-08-03 10:32:00"))
        expect(request.session[:rdv_insertion_invitation]).to eq(motif_category_short_name: "rsa_orientation")
      end

      it "redirects to current path without the token" do
        subject
        expect(response).to redirect_to("/fake_action?motif_category_short_name=rsa_orientation")
      end

      context "when a user is already connected" do
        let!(:user) { create(:user) }

        before { sign_in user }

        context "when it is the user linked to the invitation" do
          it "does stores the invitation in session and redirect" do
            subject
            expect(request.session[:restricted_auth]).to eq(invitation_token: token, expires_at: Time.zone.parse("2022-08-03 10:32:00"))
            expect(request.session[:rdv_insertion_invitation]).to eq(motif_category_short_name: "rsa_orientation")
            expect(response).to redirect_to("/fake_action?motif_category_short_name=rsa_orientation")
          end
        end

        context "when it is another user" do
          let!(:other_user) { create(:user) }

          before { sign_in other_user }

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

    let!(:token) { user.set_rdv_invitation_token! }

    before do
      request.session[:restricted_auth] = { invitation_token: token, expires_at: Time.zone.parse("2022-08-03 10:32:00") }
      request.session[:rdv_insertion_invitation] = { motif_category_short_name: "rsa_orientation" }
    end

    it "connecte l'usager et indique le mode de connexion utilisé" do
      subject
      expect(response).to be_successful
      expect(assigns(:current_user)).to eq(user)
      expect(assigns(:current_user).signed_in_with_invitation_token?).to be(true)
    end

    context "when the token is invalid" do
      let!(:token) { "some random token" }

      it "deletes the invitation and redirects to root path with a message" do
        subject
        expect(request.session[:restricted_auth]).to be_nil
        expect(response).to redirect_to(root_path)
        expect(flash[:error]).to eq("Votre invitation n'est pas valide.")
      end
    end

    context "when the session expired" do
      before do
        request.session[:restricted_auth] = { invitation_token: token, expires_at: 5.minutes.ago }
      end

      it "deletes the invitation and redirects to root path with a message" do
        subject
        expect(request.session[:restricted_auth]).to be_nil
        expect(response).to redirect_to(root_path)
        expect(flash[:error]).to eq("La session a expiré")
      end
    end

    context "when a user is logged in already" do
      context "when it is the invited user" do
        before { sign_in user }

        it "does not mark the user as only invited" do
          subject
          expect(response).to be_successful
          expect(assigns(:current_user)).to eq(user)
          expect(assigns(:current_user)).not_to(be_signed_in_with_invitation_token)
        end
      end

      context "when it is another user" do
        let!(:other_user) { create(:user) }

        before { sign_in other_user }

        it "redirects to root path with a message" do
          subject
          expect(response).to redirect_to(root_path)
          expect(flash[:error]).to eq("L’utilisateur connecté ne correspond pas à l’utilisateur invité. Déconnectez-vous et réessayez.")
        end
      end
    end
  end
end
