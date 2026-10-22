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

  context "quand l'agent est administrateur de l'espace mais n'est pas membre de toutes les organisations" do
    let!(:territory) { create(:territory) }
    let!(:organisation) { create(:organisation, territory: territory, name: "MDS de Paris Nord") }
    let!(:other_organisation) { create(:organisation, territory: territory, name: "MDS de Paris Sud") }
    let!(:another_organisation) { create(:organisation, territory: territory, name: "MDS de Paris Est") }
    let!(:closed_organisation) { create(:organisation, territory: territory, name: "MDS de Paris Ouest", disabled_at: Time.zone.now) }
    let!(:agent) { create(:agent, admin_role_in_organisations: [organisation], role_in_territories: [territory]) }

    before { login_as(agent, scope: :agent) }

    it "affiche une notice indiquant le nombre d'organisations dont il n'est pas membre" do
      visit "/admin/organisations"
      expect(page).to have_content("Il y a 2 autres organisations dans cet espace dont vous n'êtes pas membre.")
      click_on("Gérer les organisations")
      expect(page).to have_content("MDS de Paris Sud")
    end

    it "indique dans les paramètres de l'espace les organisations dont il n'est pas membre, sans lien vers leur configuration" do
      visit admin_territory_organisations_path(territory)
      expect(page).to have_link("MDS de Paris Nord", href: admin_organisation_configuration_path(organisation))
      expect(page).to have_no_link("MDS de Paris Sud")
      expect(page).to have_no_link("MDS de Paris Est")
      expect(page).to have_content("Vous n'êtes pas membre de cette organisation", count: 2)
    end

    it "permet de rejoindre une organisation depuis sa tuile" do
      visit admin_territory_organisations_path(territory)
      click_on("Rejoindre l'organisation MDS de Paris Sud")

      expect(page).to have_current_path(admin_organisation_configuration_path(other_organisation))
      expect(page).to have_content("Vous êtes maintenant administrateur de l'organisation MDS de Paris Sud.")
      expect(agent.reload.admin_in_organisation?(other_organisation)).to be(true)
    end

    it "ne propose pas de rejoindre une organisation fermée" do
      visit admin_territory_organisations_path(territory)

      expect(page).to have_button("Rejoindre l'organisation MDS de Paris Sud")
      expect(page).to have_content("MDS de Paris Ouest")
      expect(page).to have_no_button("Rejoindre l'organisation MDS de Paris Ouest")
    end
  end

  context "quand l'agent est administrateur de l'espace et membre de plusieurs organisations", :js do
    let!(:territory) { create(:territory) }
    let!(:organisation) { create(:organisation, territory: territory, name: "MDS de Paris Nord") }
    let!(:other_organisation) { create(:organisation, territory: territory, name: "MDS de Paris Sud") }
    let!(:joinable_organisation) { create(:organisation, territory: territory, name: "MDS de Paris Est") }
    let!(:agent) { create(:agent, admin_role_in_organisations: [organisation, other_organisation], role_in_territories: [territory]) }

    before { login_as(agent, scope: :agent) }

    it "affiche dans la modale de changement d'organisation une notice vers les organisations qu'il peut rejoindre" do
      visit admin_organisation_planning_agenda_path(organisation)
      click_on("Changer d'organisation")

      within("#organisation-switcher-modal") do
        expect(page).to have_content("Il y a 1 autre organisation dans cet espace dont vous n'êtes pas membre.")
        click_on("Voir les organisations de l’espace")
      end

      expect(page).to have_current_path(admin_territory_organisations_path(territory))
      expect(page).to have_button("Rejoindre l'organisation MDS de Paris Est")
    end
  end

  context "quand l'agent n'est pas administrateur de l'espace" do
    let!(:territory) { create(:territory) }
    let!(:organisation) { create(:organisation, territory: territory) }
    let!(:other_organisation) { create(:organisation, territory: territory) }
    let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

    before { login_as(agent, scope: :agent) }

    it "n'affiche pas la notice" do
      visit "/admin/organisations"
      expect(page).to have_no_content("dont vous n'êtes pas membre")
    end
  end
end
