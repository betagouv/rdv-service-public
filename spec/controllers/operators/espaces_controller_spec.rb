RSpec.describe Operators::EspacesController, type: :controller do
  describe "GET #index" do
    context "quand l’utilisateur n’est pas connecté" do
      it "redirige vers la page d’accueil et affiche un flash" do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Vous devez vous connecter ou vous inscrire pour continuer.")
      end
    end

    context "quand l’utilisateur est connecté en tant qu’operator_manager" do
      let(:operator_manager) { create :operator_manager }

      before do
        sign_in operator_manager
      end

      it "affiche la liste des espaces" do
        get :index
        expect(response).to be_successful
      end
    end
  end

  describe "GET #show" do
    context "quand l’utilisateur n’est pas connecté" do
      it "redirige vers la page d’accueil et affiche un flash" do
        territory = create(:territory)
        get :show, params: { id: territory.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Vous devez vous connecter ou vous inscrire pour continuer.")
      end
    end

    context "quand l’utilisateur est connecté en tant qu’operator_manager" do
      let(:operator_manager) { create :operator_manager }

      before do
        sign_in operator_manager
      end

      it "autorise l’accès à un espace appartenant à son opérateur" do
        territory = create(:territory, operator: operator_manager.operator)

        get :show, params: { id: territory.id }
        expect(response).to be_successful
      end

      it "refuse l’accès à un espace n’appartenant pas à son opérateur" do
        other_operator = create(:operator)
        territory = create(:territory, operator: other_operator)

        expect do
          get :show, params: { id: territory.id }
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
