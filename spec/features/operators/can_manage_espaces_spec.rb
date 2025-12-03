RSpec.describe "un opérateur peut gérer ses espaces" do
  let(:operator) { create(:operator) }
  let(:operator_manager) { create(:operator_manager, operator: operator) }
  let!(:territory) { create(:territory, operator: operator) }

  context "quand le manager n’est pas connecté" do
    it "la liste des espaces n’est pas accessible" do
      visit operators_espaces_path
      expect(page).to have_current_path(root_path)
    end

    it "la page d’un espace n’est pas accessible" do
      visit operators_espace_path(territory)
      expect(page).to have_current_path(root_path)
    end
  end

  context "quand le manager est connecté" do
    before do
      login_as(operator_manager, scope: :operator_manager)
    end

    describe "la liste des espaces" do
      it "est accessible" do
        visit operators_espaces_path
        expect(page).to have_content(territory.name)
      end
    end

    describe "la page d’un espace" do
      it "est accessible" do
        visit operators_espace_path(territory)
        expect(page).to have_content(territory.name)
      end
    end

    describe "la page d’un espace non géré par cet opérateur" do
      it "n’est pas accessible" do
        other_operator = create(:operator)
        other_territory = create(:territory, operator: other_operator)

        expect do
          visit operators_espace_path(other_territory)
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
