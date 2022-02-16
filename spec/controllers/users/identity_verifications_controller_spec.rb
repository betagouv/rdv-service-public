# frozen_string_literal: true

describe Users::IdentityVerificationsController, type: :controller do
  render_views
  let!(:user) { create(:user, last_name: "Dylan") }

  before { sign_in(user) }

  describe "GET #new" do
    it "asks for the last name first three letters" do
      get :new
      expect(response.body).to match(/Entrez les 3 premières lettres de votre nom de famille/)
    end
  end

  describe "POST #create" do
    context "when the letters matches the user last name" do
      let!(:redirect_path) { "/rdvs/29" }

      before { request.session[:return_to_after_verification] = redirect_path }

      it "sets the user as verified" do
        post :create, params: { letter0: "D", letter1: "Y", letter2: "L" }

        jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
        expect(jar.encrypted[:"user_#{user.id}_verified"]).to eq(true)
      end

      it "redirect to the path stored in session" do
        post :create, params: { letter0: "D", letter1: "Y", letter2: "L" }

        expect(response).to redirect_to(redirect_path)
      end

      context "for two letters name" do
        let!(:user) { create(:user, last_name: "Bo") }

        it "works" do
          post :create, params: { letter0: "B", letter1: "O", letter2: "" }

          jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
          expect(jar.encrypted[:"user_#{user.id}_verified"]).to eq(true)
          expect(response).to redirect_to(redirect_path)
        end
      end

      context "for composed names" do
        let!(:user) { create(:user, last_name: "De la Fontaine") }

        it "works" do
          post :create, params: { letter0: "D", letter1: "E", letter2: "L" }

          jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
          expect(jar.encrypted[:"user_#{user.id}_verified"]).to eq(true)
          expect(response).to redirect_to(redirect_path)
        end
      end
    end

    context "when the letters don't match" do
      it "does not set the user as verified" do
        post :create, params: { letter0: "D", letter1: "Y", letter2: "O" }

        jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
        expect(jar.encrypted[:"user_#{user.id}_verified"]).to be_nil
      end

      it "renders new with an error message" do
        post :create, params: { letter0: "D", letter1: "Y", letter2: "O" }

        expect(response.body).to match(/Les 3 lettres ne correspondent pas au nom de famille./)
        expect(response.body).to match(/Entrez les 3 premières lettres de votre nom de famille/)
      end
    end
  end
end
