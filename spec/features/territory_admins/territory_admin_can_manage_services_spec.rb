RSpec.describe "territory admin can manage services", type: :feature do
  let!(:territory) { create(:territory) }
  let!(:agent) { create(:agent, role_in_territories: [territory]) }

  before do
    login_as(agent, scope: :agent)
  end

  describe "Listing services" do
    let!(:service_a) { create(:service) }
    let!(:service_b) { create(:service) }
    let!(:service_c) { create(:service) }

    it "works" do
      visit edit_admin_territory_services_path(territory)

      expect(page).to have_content("Vous pouvez activer ou désactiver les services auxquels vos agents peuvent être affectés.")
      expect(page).to have_content(service_a.name)
      expect(page).to have_content(service_b.name)
      expect(page).to have_content(service_c.name)
    end
  end

  describe "Activating/Deactivating services" do
    let!(:service_a) { create(:service) }
    let!(:service_b) { create(:service) }
    let!(:service_c) { create(:service) }

    it "works" do
      visit edit_admin_territory_services_path(territory)
      check service_a.name
      check service_b.name

      expect { click_on "Enregistrer" }.to change {
        territory.reload.services.ids
      }.from([]).to([service_a.id, service_b.id])
      expect(page).to have_content("Liste des services disponibles mise à jour")

      uncheck service_b.name
      check service_c.name

      expect { click_on "Enregistrer" }.to change {
        territory.reload.services.ids
      }.from([service_a.id, service_b.id]).to([service_a.id, service_c.id])
      expect(page).to have_content("Liste des services disponibles mise à jour")
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
