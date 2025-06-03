RSpec.describe "territory admin can manage user fields", type: :feature do
  describe "affichage des champs légitimes ou déjà cochés" do
    context "quand tous les toggles sont désactivés (espace tout juste créé)" do
      let!(:territory) { create(:territory) }
      let!(:agent) { create(:agent, role_in_territories: [territory]) }

      it "affiche uniquement les champs légitimes" do
        login_as(agent, scope: :agent)
        visit edit_admin_territory_user_fields_path(territory)
        expect(page).to have_content("Date de naissance")
        expect(page).to have_content("Complément d'adresse")
        expect(page).to have_content("Numéro de dossier")

        expect(page).not_to have_content("Logement")
        expect(page).not_to have_content("Remarques")
        expect(page).not_to have_content("Caisse d'affiliation")
        expect(page).not_to have_content("Numéro d'allocataire")
        expect(page).not_to have_content("Situation familiale")
        expect(page).not_to have_content("Nombre d'enfants")
      end
    end

    context "quand certains toggles sont activés sur le territoire" do
      let!(:territory) { create(:territory, enable_logement_field: true, enable_number_of_children_field: true) }
      let!(:agent) { create(:agent, role_in_territories: [territory]) }

      it "affiche les champs légitimes et les champs activés" do
        login_as(agent, scope: :agent)
        visit edit_admin_territory_user_fields_path(territory)

        # Les champs légitimes sont affichés.
        expect(page).to have_content("Date de naissance")
        expect(page).to have_content("Complément d'adresse")
        expect(page).to have_content("Numéro de dossier")

        # Ces champs legacy sont affichés car actuellement enabled
        expect(page).to have_content("Nombre d'enfants")
        expect(page).to have_content("Logement")

        # Les autres champs legacy ne sont pas affichés
        expect(page).not_to have_content("Remarques")
        expect(page).not_to have_content("Caisse d'affiliation")
        expect(page).not_to have_content("Numéro d'allocataire")
        expect(page).not_to have_content("Situation familiale")
      end
    end
  end
end
