RSpec.describe Users::SessionsByCodeController, type: :controller do
  before { request.env["devise.mapping"] = Devise.mappings[:user] }

  describe "#new" do
    context "dans le contexte d'un rdv wizard, quand le créneau n'est plus disponible" do
      let(:motif) { create(:motif) }
      let(:rdv_builder) { instance_double(Users::RdvBuilder, motif: motif, creneau: nil, to_query: {}) }

      before do
        travel_to(Time.zone.parse("2026-01-15 10:00:00"))
        allow(Users::RdvBuilder).to receive(:new).and_return(rdv_builder)
        session[:user_return_to] = "/users/rdv_wizard_step/new?motif_id=#{motif.id}"
        get :new, params: { email: "nouvel_usager@test.fr" }
      end

      it "informe l'usager que le créneau n'est plus disponible et le redirige vers la sélection de créneau" do
        expect(flash[:error]).to eq("Ce créneau n'est plus disponible. Veuillez en sélectionner un autre ou refaire votre recherche ultérieurement.")
        expect(response.location).to include(prendre_rdv_path)
      end
    end
  end

  describe "#create" do
    context "dans le contexte d'un rdv wizard, quand le créneau n'est plus disponible" do
      let(:email) { "nouvel_usager@test.fr" }
      let!(:login_code) { create(:login_code, email: email, code: "123456") }
      let(:motif) { create(:motif) }
      let(:rdv_builder) { instance_double(Users::RdvBuilder, motif: motif, creneau: nil, to_query: {}) }

      before do
        travel_to(Time.zone.parse("2026-01-15 10:00:00"))
        allow(Users::RdvBuilder).to receive(:new).and_return(rdv_builder)
        session[:user_return_to] = "/users/rdv_wizard_step/new?motif_id=#{motif.id}"
        post :create, params: { login_code: { email:, code: "123456" } }
      end

      it "informe l'usager que le créneau n'est plus disponible et le redirige vers la sélection de créneau" do
        expect(flash[:error]).to eq("Ce créneau n'est plus disponible. Veuillez en sélectionner un autre ou refaire votre recherche ultérieurement.")
        expect(response.location).to include(prendre_rdv_path)
      end
    end
  end

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
