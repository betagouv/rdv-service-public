RSpec.describe "Lister les organisations et y naviguer" do
  context "quand l'agent a une seule organisation" do
    let!(:organisation) { create(:organisation, name: "Mon unique orga") }
    let!(:agent) { create(:agent, admin_role_in_organisations: [organisation], role_in_territories: [organisation.territory]) }

    before { login_as(agent, scope: :agent) }

    it "la page d'accueil redirige vers cette orga" do
      visit "/"
      expect(page).to have_current_path("/admin/organisations/#{organisation.id}/planning/agenda")
    end

    it "un clic sur le logo renvoie vers l'accueil de cette orga" do
      visit "/admin/organisations/#{organisation.id}/users"
      find("header nav a.header-brand").click
      expect(page).to have_current_path("/admin/organisations/#{organisation.id}/planning/agenda")
    end

    it "permet de lister son unique orga" do
      visit "/admin/organisations"
      expect(page).to have_current_path("/admin/organisations")

      click_on("Retour à l'accueil")
      expect(page).to have_current_path("/admin/organisations/#{organisation.id}/planning/agenda")
    end
  end

  context "quand l'agent a plusieurs organisations" do
    let!(:territory) { create(:territory) }
    let!(:organisation1) { create(:organisation, territory: territory, name: "MDS de Paris Nord") }
    let!(:organisation2) { create(:organisation, territory: territory, name: "MDS de Paris Sud") }
    let!(:agent) { create(:agent, admin_role_in_organisations: [organisation1, organisation2], role_in_territories: [territory]) }

    before { login_as(agent, scope: :agent) }

    it "redirige vers la liste des organisations si l'agent n'a visité aucune orga précédemment" do
      visit "/"
      expect(page).to have_current_path("/admin/organisations")
      expect(page).to have_content("MDS de Paris Nord")
      expect(page).to have_content("MDS de Paris Sud")
    end

    # TODO: corriger ce problème (boucle infinie si je n'ai jamais visité d'orga)
    it "enferme l'agent sur la page de choix d'orga" do
      visit "/admin/organisations"
      click_on("Retour à l'accueil")
      expect(page).to have_current_path("/admin/organisations")
    end

    context "quand l'agent a déjà visité une organisation" do
      before do
        visit "/admin/organisations/#{organisation2.id}/support" # l'agent a déjà visité organisation2
      end

      it "une visite du root path redirige vers le choix d'orga" do
        visit "/"
        expect(page).to have_current_path("/admin/organisations")
      end

      it "un clic sur le logo renvoie vers le choix d'orga" do
        visit "/admin/organisations/#{organisation1.id}/users"
        find("header nav a.header-brand").click
        expect(page).to have_current_path("/admin/organisations")
      end

      it "sur la liste des orgas, le bouton de retour à l'accueil pointe vers la dernière orga visitée" do
        visit "/admin/organisations"
        expect(page).to have_current_path("/admin/organisations")
        click_on("Retour à l'accueil")
        expect(page).to have_current_path("/admin/organisations/#{organisation2.id}/planning/agenda")
      end
    end
  end
end
