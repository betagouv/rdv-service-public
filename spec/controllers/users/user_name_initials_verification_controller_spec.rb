RSpec.describe Users::UserNameInitialsVerificationController, type: :controller do
  render_views
  let!(:user) { create(:user, last_name: "Dylan") }
  let!(:participation) { create(:participation, user:) }

  before do
    session[:information_for_name_verification] = {
      user_id: participation.user_id,
      rdv_id: participation.rdv_id,
    }
  end

  describe "GET #new" do
    it "asks for the last name first three letters" do
      get :new
      expect(response.body).to match(/3 premières lettres de votre nom/)
    end
  end

  describe "POST #create" do
    context "when the letters matches the user last name" do
      let!(:redirect_path) { "/rdvs/29" }

      before { request.session[:return_to_after_verification] = redirect_path }

      it "sets the user as verified" do
        post :create, params: { letters: "DYL" }

        expect(session[:restricted_auth]).to include(user_id: participation.user_id, rdv_id: participation.rdv_id)
      end

      it "redirect to the path stored in session" do
        post :create, params: { letters: "DYL" }

        expect(response).to redirect_to(redirect_path)
      end

      context "for two letters name" do
        let!(:user) { create(:user, last_name: "Bo") }

        it "works" do
          post :create, params: { letters: "BO" }

          expect(session[:restricted_auth]).to include(user_id: participation.user_id, rdv_id: participation.rdv_id)
          expect(response).to redirect_to(redirect_path)
        end
      end

      context "for composed names" do
        let!(:user) { create(:user, last_name: "De la Fontaine") }

        it "works" do
          post :create, params: { letters: "DEL" }

          expect(session[:restricted_auth]).to include(user_id: participation.user_id, rdv_id: participation.rdv_id)
          expect(response).to redirect_to(redirect_path)
        end
      end

      context "when the redirect path is not specified in the session" do
        before { request.session[:return_to_after_verification] = nil }

        it "redirects to root_path" do
          post :create, params: { letters: "DYL" }

          expect(response).to redirect_to(root_path)
        end
      end
    end

    context "when the letters don't match" do
      it "does not set the user as verified" do
        post :create, params: { letters: "DYO" }

        expect(session[:restricted_auth]).to be_nil
      end

      it "renders new with an error message" do
        post :create, params: { letters: "DYO" }

        expect(response.body).to match(/Les 3 lettres ne correspondent pas au nom de famille./)
        expect(response.body).to match(/3 premières lettres de votre nom/)
      end
    end
  end
end
