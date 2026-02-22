RSpec.describe "admin d'espace peut gérer les champs de fiche usager", type: :feature do
  let!(:territory) { territories(:default_territory) }
  let!(:agent) { create(:agent, role_in_territories: [territory]) }

  it "works (cas général)" do
    login_as(agent, scope: :agent)
    visit edit_admin_territory_user_fields_path(territory)

    check "Date de naissance"
    expect { click_on "Enregistrer" }.to change { territory.reload.enable_birth_date_field }.from(false).to(true)

    uncheck "Date de naissance"
    expect { click_on "Enregistrer" }.to change { territory.reload.enable_birth_date_field }.from(true).to(false)
  end

  it "permet de décocher les champs legcay précédemment activés" do
    territory.update!(enable_logement_field: true)
    login_as(agent, scope: :agent)
    visit edit_admin_territory_user_fields_path(territory)

    uncheck "Logement"
    expect { click_on "Enregistrer" }.to change { territory.reload.enable_logement_field }.from(true).to(false)
    # Le champ n'est plus proposé une fois décoché
    expect(page).not_to have_content("Logement")
  end

  describe "affichage des champs légitimes ou déjà cochés" do
    context "quand tous les toggles sont désactivés (espace tout juste créé)" do
      let!(:territory) do
        create(
          :territory,
          enable_notes_field: false,
          enable_caisse_affiliation_field: false,
          enable_affiliation_number_field: false,
          enable_family_situation_field: false,
          enable_number_of_children_field: false,
          enable_logement_field: false,
          enable_case_number: false,
          enable_birth_date_field: false,
          enable_address_details: false
        )
      end
      let!(:agent) { create(:agent, role_in_territories: [territory]) }

      it "affiche uniquement les champs légitimes" do
        login_as(agent, scope: :agent)
        visit edit_admin_territory_user_fields_path(territory)

        # Les champs légitimes sont affichés
        expect(page).to have_content("Date de naissance")
        expect(page).to have_content("Complément d'adresse")
        expect(page).to have_content("Numéro de dossier")

        # pas la peine d'afficher les infos sur les champs legacy
        expect(page).not_to have_content("Les champs ci-dessous sont dépréciés")

        # Aucun champ legacy n'est affiché
        expect(page).not_to have_content("Logement")
        expect(page).not_to have_content("Remarques")
        expect(page).not_to have_content("Caisse d'affiliation")
        expect(page).not_to have_content("Numéro d'allocataire")
        expect(page).not_to have_content("Situation familiale")
        expect(page).not_to have_content("Nombre d'enfants")
      end
    end

    context "quand certains toggles sont activés sur le territoire" do
      let!(:territory) do
        create(
          :territory,
          enable_notes_field: false,
          enable_caisse_affiliation_field: false,
          enable_affiliation_number_field: false,
          enable_family_situation_field: false,
          enable_number_of_children_field: true,
          enable_logement_field: true,
          enable_case_number: false,
          enable_birth_date_field: false,
          enable_address_details: false
        )
      end
      let!(:agent) { create(:agent, role_in_territories: [territory]) }

      it "affiche les champs légitimes et les champs activés" do
        login_as(agent, scope: :agent)
        visit edit_admin_territory_user_fields_path(territory)

        # Les champs légitimes sont affichés.
        expect(page).to have_content("Date de naissance")
        expect(page).to have_content("Complément d'adresse")
        expect(page).to have_content("Numéro de dossier")

        # On affiche une explication sur le fonctionnement des champs legacy
        expect(page).to have_content("Les champs ci-dessous sont dépréciés")

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
