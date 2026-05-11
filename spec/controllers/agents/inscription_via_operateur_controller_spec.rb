RSpec.describe Agents::InscriptionViaOperateurController, type: :controller do
  describe "#show" do
    let(:agent) { create(:agent) }

    before { sign_in agent }

    context "quand les données opérateur sont présentes en session" do
      before do
        session[:inscription_via_operateur] = { "operator_name" => "Megalis", "signup_url" => "https://www.megalis-test-operateur.fr/contact" }
      end

      it "affiche la page" do
        get :show
        expect(response).to have_http_status(:ok)
      end

      it "consomme les données de session (protection contre le rechargement direct)" do
        get :show
        expect(session[:inscription_via_operateur]).to be_nil
      end
    end

    context "quand les données opérateur sont absentes de la session (accès direct à l'URL)" do
      it "redirige avec une erreur" do
        get :show
        expect(response).to redirect_to(root_path)
        expect(flash[:error]).to be_present
      end
    end
  end
end
