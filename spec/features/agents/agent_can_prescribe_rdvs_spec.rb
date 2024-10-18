RSpec.describe "agents can prescribe rdvs" do
  before do
    travel_to(now)
    stub_request(
      :get,
      "https://api-adresse.data.gouv.fr/search/?q=16%20Quai%20de%20la%20Loire,%20Paris,%2075019"
    ).to_return(status: 200, body: file_fixture("geocode_result.json").read, headers: {})
  end

  let(:now) { Time.zone.parse("2024-01-05 16h00") }
  let!(:territory) { create(:territory, departement_number: "75") }

  let!(:service_rsa) { create(:service, name: "Service RSA") }
  let!(:service_autre) { create(:service, name: "Service autre") }

  let!(:org_mds) { create(:organisation, territory: territory) }
  let!(:org_insertion) { create(:organisation, territory: territory) }

  # L'agent connecté est en MDS et veut prescrire vers d'autres orgas
  let!(:current_agent) { create(:agent, :with_territory_access_rights, admin_role_in_organisations: [org_mds], services: [service_rsa]) }
  let!(:agent_insertion) { create(:agent, :with_territory_access_rights, admin_role_in_organisations: [org_insertion], services: [service_rsa, service_autre]) }

  let!(:motif_mds) { create(:motif, organisation: org_mds, service: service_rsa) }
  let!(:motif_insertion) { create(:motif, organisation: org_insertion, service: service_rsa) }
  let!(:motif_autre_service) { create(:motif, organisation: org_insertion, service: service_autre) }

  let!(:mds_paris_nord) { create(:lieu, organisation: org_mds) }
  let!(:mission_locale_paris_nord) { create(:lieu, organisation: org_insertion) }
  let!(:mission_locale_paris_sud) { create(:lieu, organisation: org_insertion) }

  before do
    next_month = (now + 1.month).to_date
    create(:plage_ouverture, :weekdays, first_day: next_month, motifs: [motif_mds], lieu: mds_paris_nord, organisation: org_mds)
    create(:plage_ouverture, :weekdays, first_day: next_month, motifs: [motif_insertion], lieu: mission_locale_paris_sud, organisation: org_insertion, agent: agent_insertion)
    create(:plage_ouverture, :weekdays, first_day: next_month, motifs: [motif_insertion], lieu: mission_locale_paris_nord, organisation: org_insertion)
    create(:plage_ouverture, :weekdays, first_day: next_month, motifs: [motif_autre_service], lieu: mission_locale_paris_sud, organisation: org_insertion)
    current_agent.reload # needed to populate agent.organisations :/
    agent_insertion.reload
  end

  def go_to_prescription_page
    login_as(current_agent, scope: :agent)
    visit root_path
    within(".left-side-menu") { click_on "Trouver un RDV" }
    click_link "Élargir la recherche"
  end

  describe 'using "Trouver un RDV"' do
    let!(:existing_user) { create(:user, first_name: "Francis", last_name: "FACTICE", organisations: [org_mds], address: "16 Quai de la Loire, Paris, 75019") }

    it "works (happy path)", js: true do
      go_to_prescription_page
      expect(page).to have_content("Nouveau RDV par prescription")
      # Select Service
      expect(page).to have_content("Sélectionnez le service avec qui vous voulez prendre un RDV")
      expect(page).to have_content(motif_mds.service.name)
      expect(page).to have_content(motif_autre_service.service.name)
      find("h3", text: motif_mds.service.name).ancestor("a").click
      # Select Motif
      expect(page).to have_content("Sélectionnez le motif de votre RDV")
      expect(page).to have_content(motif_mds.name)
      expect(page).to have_content(motif_insertion.name)
      find("h3", text: motif_insertion.name).ancestor("a").click
      # Select Lieu
      expect(page).to have_content(mission_locale_paris_sud.name)
      expect(page).to have_content(mission_locale_paris_nord.name)
      find(".card-title", text: /#{mission_locale_paris_nord.name}/).ancestor(".card").find("a.stretched-link").click
      # Select créneau
      expect(page).to have_content(mission_locale_paris_nord.name)
      first(:link, "11:00").click
      # Display User selection
      find(".select2-selection[aria-labelledby=select2-user_ids_-container]").click
      find(".select2-search__field").send_keys("francis")
      expect(page).to have_content("FACTICE Francis")
      first(".select2-results ul.select2-results__options li").click
      click_on "Continuer"
      # Display Récapitulatif
      expect(page).to have_content("Motif : #{motif_insertion.name}")
      expect(page).to have_content("Lieu : #{mission_locale_paris_nord.name}")
      expect(page).to have_content("Date du rendez-vous :")
      expect(page).to have_content("Usager : FACTICE Francis")
      expect { click_button "Confirmer le rdv" }.to change(Rdv, :count).by(1)
      # Display Confirmation
      expect(page).to have_content("Rendez-vous confirmé")
      created_rdv = Rdv.last
      expect(created_rdv.users.first).to eq(existing_user)
      # User ends up in current org, distant org, and other orgs she was already in
      expect(created_rdv.users.first.organisations).to contain_exactly(org_mds, org_insertion)
      expect(created_rdv.organisation).to eq(org_insertion)
      expect(created_rdv.motif).to eq(motif_insertion)
      expect(created_rdv.lieu).to eq(mission_locale_paris_nord)
      expect(created_rdv.starts_at).to eq(Time.zone.parse("2024-02-05 11:00"))
      expect(created_rdv.created_by).to eq(current_agent)
      expect(created_rdv.participations.last.created_by).to eq(current_agent)
      expect(created_rdv.participations.last.created_by_agent_prescripteur).to be(true)
    end

    describe "for a collective rdv" do
      let!(:motif_collectif) { create(:motif, :collectif, organisation: org_mds, service: service_rsa) }
      let!(:collective_rdv) { create(:rdv, :collectif, organisation: org_mds, starts_at: now + 1.day, motif: motif_collectif, lieu: mds_paris_nord, created_by: current_agent) }

      it "works", js: true do
        go_to_prescription_page
        expect(page).to have_content("Nouveau RDV par prescription")
        # Select Service
        expect(page).to have_content("Sélectionnez le service avec qui vous voulez prendre un RDV")
        expect(page).to have_content(motif_collectif.service.name)
        find("h3", text: motif_collectif.service.name).ancestor("a").click
        # Select Motif
        expect(page).to have_content("Sélectionnez le motif de votre RDV")
        expect(page).to have_content(motif_mds.name)
        expect(page).to have_content(motif_collectif.name)
        find("h3", text: motif_collectif.name).ancestor("a").click
        # Select Lieu
        find(".card-title", text: /#{mds_paris_nord.name}/).ancestor(".card").find("a.stretched-link").click
        # Select créneau
        first(:link, "S'inscrire").click
        # Display User selection
        find(".select2-selection[aria-labelledby=select2-user_ids_-container]").click
        find(".select2-search__field").send_keys("francis")
        expect(page).to have_content("FACTICE Francis")
        first(".select2-results ul.select2-results__options li").click
        click_on "Continuer"
        # Display Récapitulatif
        expect(page).to have_content("Motif : #{motif_collectif.name}")
        expect(page).to have_content("Lieu : #{mds_paris_nord.name}")
        expect(page).to have_content("Date du rendez-vous :")
        expect(page).to have_content("Usager : FACTICE Francis")
        expect { click_button "Confirmer le rdv" }.to change(Rdv.last.reload.participations, :count).by(1)
        expect(Rdv.last.participations.where(user: existing_user).first.created_by_agent_prescripteur).to be(true)
      end
    end
  end

  describe "creating a user along the way" do
    it "leaves the user both in local and distant organisation", js: true do
      go_to_prescription_page
      # Select Service
      find("h3", text: motif_mds.service.name).ancestor("a").click
      # Select Motif
      find("h3", text: motif_insertion.name).ancestor("a").click
      # Select Lieu
      find(".card-title", text: /#{mission_locale_paris_nord.name}/).ancestor(".card").find("a.stretched-link").click
      # Select créneau
      first(:link, "11:00").click
      # Display User selection
      click_on "Créer un usager"
      fill_in :user_first_name, with: "Jean-Paul"
      fill_in :user_last_name, with: "Orvoir"
      click_on "Créer usager"
      expect(page).to have_content("Jean-Paul")
      click_on "Continuer"
      expect { click_button "Confirmer le rdv" }.to change(Rdv, :count).by(1)
      expect(Rdv.last.users.first.organisations).to contain_exactly(org_mds, org_insertion)
      expect(Rdv.last.participations.first.created_by_agent_prescripteur).to be(true)
    end

    # Cette spec a été ajoutée suite à un bug qui faisait qu'on si on
    # revenait à l'étape de sélection usager et qu'on en créait un nouveau,
    # il n'était pas validé car le `user_ids` de l'ancien restant dans l'URL.
    it "allows going back to change the user", js: true do
      go_to_prescription_page
      # Select Service
      find("h3", text: motif_mds.service.name).ancestor("a").click
      # Select Motif
      find("h3", text: motif_insertion.name).ancestor("a").click
      # Select Lieu
      find(".card-title", text: /#{mission_locale_paris_nord.name}/).ancestor(".card").find("a.stretched-link").click
      # Select créneau
      first(:link, "11:00").click
      # Display User selection
      click_on "Créer un usager"
      fill_in :user_first_name, with: "Jean-Paul"
      fill_in :user_last_name, with: "Orvoir"
      click_on "Créer usager"
      expect(page).to have_content("Jean-Paul")
      click_on "Continuer"
      # go back to user selection
      page.all("a").find { _1.text == "modifier" && _1[:href].include?("user_selection") }.click
      click_on "Créer un usager"
      fill_in :user_first_name, with: "Jean-Pierre"
      fill_in :user_last_name, with: "Bonjour"
      click_on "Créer usager"
      expect(page).to have_content("BONJOUR Jean-Pierre")
      click_on "Continuer"
      expect { click_button "Confirmer le rdv" }.to change(Rdv, :count).by(1)
      expect(Rdv.last.users.first.full_name).to eq("Jean-Pierre BONJOUR")
      expect(Rdv.last.participations.first.created_by_agent_prescripteur).to be(true)
    end
  end

  describe "starting from a user profile" do
    let!(:user) { create(:user, organisations: [org_mds], address: "16 Quai de la Loire, Paris, 75019") }

    it "pre-fills the user" do
      login_as(current_agent, scope: :agent)
      visit admin_organisation_user_path(org_mds, id: user.id)
      within(".content") { click_on "Trouver un RDV" } # Trouver un RDV pour l'usager
      click_link "Élargir la recherche"
      expect(page).to have_content("Nouveau RDV par prescription")
      expect(page).to have_content("pour #{user.full_name}")
      # Select Service
      find("h3", text: motif_mds.service.name).ancestor("a").click
      # Select Motif
      expect(page).to have_content("Sélectionnez le motif de votre RDV")
      find("h3", text: motif_mds.name).ancestor("a").click
      # Select Lieu
      find(".card-title", text: /#{mds_paris_nord.name}/).ancestor(".card").find("a.stretched-link").click
      expect(page).to have_content(mds_paris_nord.name)
      # Select créneau
      first(:link, "11:00").click
      # Display Récapitulatif
      expect { click_button "Confirmer le rdv" }.to change(Rdv, :count).by(1)
      # Display Confirmation
      expect(page).to have_content("Rendez-vous confirmé")
      expect(Rdv.last.users.first).to eq(user)
      expect(Rdv.last.participations.first.created_by_agent_prescripteur).to be(true)
    end

    describe "with sectorization", js: true do
      let!(:sector) { create(:sector, territory: territory) }
      let!(:sector_attribution) { create(:sector_attribution, sector: sector, organisation: org_mds) }
      let!(:zone) do
        create(
          :zone,
          sector: sector,
          level: "street",
          street_ban_id: "75119_5732",
          street_name: "Quai de la Loire",
          city_name: "Paris",
          city_code: "75119"
        )
      end

      before do
        motif_mds.update(sectorisation_level: "organisation")
        motif_insertion.update(sectorisation_level: "organisation")
        motif_autre_service.update(sectorisation_level: "organisation")

        login_as(current_agent, scope: :agent)
        visit admin_organisation_creneaux_search_path(org_mds, user_ids: [user.id])
        click_link "Élargir la recherche"
      end

      it "when sectorization is enabled on the user street level only it show the street leveled motif only" do
        expect(page).not_to have_content(motif_insertion.name)
        expect(page).not_to have_content(motif_autre_service.name)
        expect(page).to have_content(motif_mds.service.name)
        expect(page).to have_content(motif_mds.name)
        click_on motif_mds.name
        find(".card-title", text: /#{mds_paris_nord.name}/).ancestor(".card").find("a.stretched-link").click
        first(:link, "11:00").click
        expect { click_button "Confirmer le rdv" }.to change(Rdv, :count).by(1)
      end

      context "when sectorization is enabled on the street level and on city level on 2 differents sectors" do
        before do
          # on crée un zone de niveau "city" liée au à l'orga org_insertion
          # afin de vérifier que les motifs de cette orga sont bien affichés
          sector_of_city_zone = create(:sector, territory: territory)
          create(:sector_attribution, sector: sector_of_city_zone, organisation: org_insertion)
          create(:zone, sector: sector_of_city_zone, level: "city", city_name: "Paris", city_code: "75119")
        end

        it "show both services and motifs" do
          if Date.new(2024, 10, 19).future?
            pending # rubocop:disable RSpec/Pending
            raise "cette flaky spec a été désactivée pendant un mois le temps de travailler dessus"
          end

          expect(page).to have_content(motif_mds.service.name)
          expect(page).to have_content(motif_insertion.service.name)
          click_on motif_mds.service.name
          expect(page).to have_content(motif_mds.name)
          click_on motif_mds.name
          # Back to service selection
          page.go_back
          page.go_back
          click_on motif_insertion.service.name
          expect(page).to have_content(motif_insertion.name)
          click_on motif_insertion.name
          find(".card-title", text: /#{mission_locale_paris_nord.name}/).ancestor(".card").find("a.stretched-link").click
          first(:link, "11:00").click
          expect { click_button "Confirmer le rdv" }.to change(Rdv, :count).by(1)
        end
      end
    end
  end

  describe "when using a user from another organisation in the same territory" do
    let!(:organisation_mystere) { create(:organisation, territory: territory) }
    let!(:user_in_organisation_mystere) do
      create(
        :user,
        first_name: "Miss",
        last_name: "Terre",
        email: "miss_terre@example.com",
        phone_number: "0611223344",
        birth_date: Date.parse("1985-07-20"),
        organisations: [organisation_mystere]
      )
    end

    it "truncates personal info while searching, also add the user to destination organisation", js: true do
      login_as(current_agent, scope: :agent)
      visit root_path
      within(".left-side-menu") { click_on "Trouver un RDV" }
      click_link "Élargir la recherche"
      # Select Service
      find("h3", text: motif_mds.service.name).ancestor("a").click
      # Select Motif
      find("h3", text: motif_insertion.name).ancestor("a").click
      # Select Lieu
      find(".card-title", text: /#{mission_locale_paris_nord.name}/).ancestor(".card").find("a.stretched-link").click
      # Select créneau
      first(:link, "11:00").click
      # Display User selection
      find(".select2-selection[aria-labelledby=select2-user_ids_-container]").click
      find(".select2-search__field").send_keys("terre")
      expect(page).to have_content("TERRE Miss - 20/07/**** - 06******44 - m******e@example.com")
      first(".select2-results ul.select2-results__options li").click
      click_on "Continuer"
      # Display Récapitulatif
      # les infos de l'usager sont affichées dans le recap
      expect(page).to have_content("Usager : TERRE Miss - 20/07/1985 - 06 11 22 33 44 - miss_terre@example.com")
      expect { click_button "Confirmer le rdv" }.to change(Rdv, :count).by(1)
      # Display Confirmation
      expect(page).to have_content("Rendez-vous confirmé")
      created_rdv = Rdv.last
      expect(created_rdv.users.first).to eq(user_in_organisation_mystere)
      # User ends up in distant org, and other orgs she was already in
      expect(created_rdv.users.first.organisations).to contain_exactly(organisation_mystere, org_insertion)
    end
  end

  describe "service restriction" do
    context "when agent is admin in current org" do
      let!(:current_agent) { create(:agent, admin_role_in_organisations: [org_mds], services: [service_rsa]) }

      it "only show the motif of the agent's service(s)" do
        go_to_prescription_page
        expect(page).to have_content(service_rsa.name)
        expect(page).to have_content(service_autre.name)
      end
    end

    context "when agent is not admin in current org but is a secretaire" do
      let!(:current_agent) { create(:agent, basic_role_in_organisations: [org_mds], services: [create(:service, :secretariat)]) }

      it "only show the motif of the agent's service(s)" do
        go_to_prescription_page
        expect(page).to have_content(service_rsa.name)
        expect(page).to have_content(service_autre.name)
      end
    end

    context "when agent is basic in current org" do
      let!(:current_agent) { create(:agent, basic_role_in_organisations: [org_mds], services: [service_rsa]) }

      it "only show the motif of the agent's service(s)" do
        go_to_prescription_page
        expect(page).to have_content(service_rsa.name)
        expect(page).not_to have_content(service_autre.name)
      end
    end
  end
end
