RSpec.describe Users::SessionsByCodeController, type: :controller do
  before { request.env["devise.mapping"] = Devise.mappings[:user] }

  describe "#submit_choix_fiche_usager" do
    context "sans session courante" do
      it "redirige vers la page de connexion avec une erreur" do
        post :submit_choix_fiche_usager, params: { user_id: 0 }
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:error]).to be_present
      end
    end

    context "quand le user_id ne correspond pas à l'email en session (tentative de détournement)" do
      let!(:user_alice) { create(:user, email: "alice@test.fr") }
      let!(:user_bob)   { create(:user, email: "bob@test.fr") }

      before { session[:current_user_email] = "alice@test.fr" }

      it "redirige vers la page de connexion sans connecter l'usager" do
        post :submit_choix_fiche_usager, params: { user_id: user_bob.id }
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:error]).to be_present
      end
    end

    context "quand les noms en session diffèrent de la fiche choisie" do
      let!(:user) { create(:user, email: "test@test.fr", first_name: "Alice", last_name: "Dupont") }

      before do
        session[:current_user_email] = "test@test.fr"
        session[:wizard_first_name]  = "Bob"
        session[:wizard_last_name]   = "Martin"
      end

      it "affiche un flash notice invitant à utiliser le système de prise de rdv pour un proche" do
        post :submit_choix_fiche_usager, params: { user_id: user.id }
        expect(flash[:notice]).to include("système de prise de rdv pour un proche")
      end
    end

    context "quand les noms en session correspondent à la fiche choisie" do
      let!(:user) { create(:user, email: "test@test.fr", first_name: "Alice", last_name: "Dupont") }

      before do
        session[:current_user_email] = "test@test.fr"
        session[:wizard_first_name]  = "Alice"
        session[:wizard_last_name]   = "Dupont"
      end

      it "n'affiche pas de flash notice proche" do
        post :submit_choix_fiche_usager, params: { user_id: user.id }
        expect(flash[:notice]).to be_nil
      end
    end

    context "sans noms en session (login spontané, pas de wizard)" do
      let!(:user) { create(:user, email: "test@test.fr", first_name: "Alice", last_name: "Dupont") }

      before { session[:current_user_email] = "test@test.fr" }

      it "n'affiche pas de flash notice proche" do
        post :submit_choix_fiche_usager, params: { user_id: user.id }
        expect(flash[:notice]).to be_nil
      end
    end
  end

  describe "#create — wizard context" do
    let!(:territory)    { create(:territory) }
    let!(:organisation) { create(:organisation, territory: territory) }
    let!(:user)         { create(:user, email: "test@test.fr", first_name: "Alice", last_name: "Dupont", organisations: [organisation]) }
    let!(:login_code)   { create(:login_code, email: "test@test.fr", code: "123456", first_name: "Bob", last_name: "Martin") }

    before do
      allow(controller).to receive(:set_rdv_wizard_from_devise_return_path) do
        mock_org    = instance_double(Organisation, territory_id: territory.id)
        mock_motif  = instance_double(Motif, organisation: mock_org)
        mock_wizard = instance_double(Users::RdvBuilder, motif: mock_motif)
        controller.instance_variable_set(:@rdv_wizard, mock_wizard)
      end
    end

    it "affiche un flash notice si les noms du formulaire diffèrent de la fiche trouvée" do
      post :create, params: { login_code: { email: "test@test.fr", code: "123456" } }
      expect(flash[:notice]).to include("système de prise de rdv pour un proche")
    end

    context "quand les noms correspondent" do
      let!(:login_code) { create(:login_code, email: "test@test.fr", code: "123456", first_name: "Alice", last_name: "Dupont") }

      it "ne affiche pas de flash notice proche" do
        post :create, params: { login_code: { email: "test@test.fr", code: "123456" } }
        expect(flash[:notice]).to be_nil
      end
    end
  end
end
