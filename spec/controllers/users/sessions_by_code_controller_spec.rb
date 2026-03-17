RSpec.describe Users::SessionsByCodeController, type: :controller do
  before { request.env["devise.mapping"] = Devise.mappings[:user] }

  describe "#choix_fiche_usager" do
    context "sans cookie de sélection" do
      it "redirige vers la page de connexion avec une erreur" do
        post :choix_fiche_usager, params: { user_id: 0 }
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:error]).to be_present
      end
    end

    context "quand le user_id ne correspond pas à l'email dans le cookie (tentative de détournement)" do
      let!(:user_alice) { create(:user, email: "alice@test.fr") }
      let!(:user_bob)   { create(:user, email: "bob@test.fr") }

      before { cookies.encrypted[:fiche_selection_email] = { "email" => "alice@test.fr" } }

      it "redirige vers la page de connexion sans connecter l'usager" do
        post :choix_fiche_usager, params: { user_id: user_bob.id }
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:error]).to be_present
      end
    end
  end
end
