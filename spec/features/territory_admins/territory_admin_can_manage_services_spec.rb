RSpec.describe "territory admin can manage services", type: :feature do
  let!(:territory) { create(:territory) }
  let!(:agent) { create(:agent, role_in_territories: [territory]) }

  before do
    login_as(agent, scope: :agent)
  end

  describe "Activating/Deactivating services" do
    it "works" do
      pmi = create(:service, :pmi)
      social = create(:service, :social)
      visit edit_admin_territory_services_path(territory)
      expect(territory.reload.services).to be_empty

      # Lier un service existant
      check pmi.name
      click_on "Valider la sélection"
      expect(territory.reload.services).to eq([pmi])

      # Dé-lier un service
      uncheck pmi.name
      click_on "Valider la sélection"
      expect(territory.reload.services).to eq([])

      # Filtrage puis ajout
      fill_in "Trouvez un service par nom", with: "social"
      click_on "Filtrer"
      expect(page).to have_content(social.name)
      expect(page).not_to have_content(pmi.name)
      check social.name
      click_on "Valider la sélection"
      expect(territory.reload.services).to eq([social])
      fill_in "Trouvez un service par nom", with: "pmi"
      click_on "Filtrer"
      expect(page).to have_content(pmi.name)
      expect(page).not_to have_content(social.name)
      check pmi.name
      click_on "Valider la sélection"
      expect(territory.reload.services).to contain_exactly(social, pmi)
    end
  end

  describe "creating a new service" do
    it "works" do
      visit new_admin_territory_services_path(territory_id: territory.id)
      fill_in "Intitulé du nouveau service", with: "Protection maternelle et infantile"
      fill_in "Intitulé court du nouveau service", with: "PMI"
      expect { click_on("Ajouter le nouveau service") }.to change(Service, :count).by(1).and(change { territory.services.reload.size }.by(1))
      expect(Service.last).to have_attributes(name: "Protection maternelle et infantile", short_name: "PMI")
      expect(page).to have_content(%(Le service "Protection maternelle et infantile (PMI)" vient d'être créé et activé dans votre espace.))
    end

    describe "validations" do
      it "displays error message if the names are too short or too long", type: :request do
        post admin_territory_services_path(territory_id: territory.id), params: { service: { name: "a" } }
        expect(response.body).to include("Le nom du service doit contenir au moins 2 caractères.")
        expect(response.body).to include("Le nom raccourci pour les SMS doit contenir au moins 2 caractères.")

        post admin_territory_services_path(territory_id: territory.id), params: { service: { name: "a" * 70, short_name: "a" * 50 } }
        expect(response.body).to include("Le nom du service ne doit pas dépasser 60 caractères.")
        expect(response.body).to include("Le nom raccourci pour les SMS ne doit pas dépasser 40 caractères.")
      end

      it "displays error message if the name already exists" do
        create(:service, name: "Protection maternelle et infantile")
        visit new_admin_territory_services_path(territory_id: territory.id)
        fill_in "Intitulé du nouveau service", with: "Protection maternelle et infantile"
        fill_in "Intitulé court du nouveau service", with: "PMI"
        click_on("Ajouter le nouveau service")
        expect(page).to have_content("Le nom du service est déjà présent dans la liste de services existants")
      end
    end
  end
end
