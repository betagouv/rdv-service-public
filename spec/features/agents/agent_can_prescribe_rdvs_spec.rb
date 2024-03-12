RSpec.describe "agents can prescribe rdvs" do
  before do
    travel_to(now)
    stub_request(
      :get,
      "https://api-adresse.data.gouv.fr/search/?q=20%20avenue%20de%20S%C3%A9gur,%20Paris"
    ).to_return(status: 200, body: file_fixture("geocode_result.json").read, headers: {})
  end

  let(:now) { Time.zone.parse("2024-01-05 16h00") }
  let!(:territory) { create(:territory, departement_number: "83") }
  let!(:org_mds) { create(:organisation, territory: territory) }
  let!(:org_insertion) { create(:organisation, territory: territory) }

  let!(:agent_mds) { create(:agent, :with_territory_access_rights, admin_role_in_organisations: [org_mds]) }
  let!(:agent_insertion) { create(:agent, :with_territory_access_rights, admin_role_in_organisations: [org_insertion]) }

  let!(:motif_mds) { create(:motif, organisation: org_mds, service: agent_mds.services.first) }
  let!(:motif_insertion) { create(:motif, organisation: org_insertion, service: agent_mds.services.first) }
  let!(:motif_autre_service) { create(:motif, organisation: org_insertion) }
  let!(:motif_collectif) { create(:motif, :collectif, organisation: org_mds) }

  let!(:mds_paris_nord) { create(:lieu, organisation: org_mds) }
  let!(:mission_locale_paris_nord) { create(:lieu, organisation: org_insertion) }
  let!(:mission_locale_paris_sud) { create(:lieu, organisation: org_insertion) }
  let!(:collective_rdv) { create(:rdv, :collectif, organisation: org_mds, starts_at: now + 1.day, motif: motif_collectif, lieu: mds_paris_nord, created_by: agent_mds) }

  before do
    next_month = (now + 1.month).to_date
    create(:plage_ouverture, :daily, first_day: next_month, motifs: [motif_mds], lieu: mds_paris_nord, organisation: org_mds)
    create(:plage_ouverture, :daily, first_day: next_month, motifs: [motif_insertion], lieu: mission_locale_paris_sud, organisation: org_insertion, agent: agent_insertion)
    create(:plage_ouverture, :daily, first_day: next_month, motifs: [motif_insertion], lieu: mission_locale_paris_nord, organisation: org_insertion)
    create(:plage_ouverture, :daily, first_day: next_month, motifs: [motif_autre_service], lieu: mission_locale_paris_sud, organisation: org_insertion)
  end

  describe 'using "Trouver un RDV"' do
    let!(:existing_user) { create(:user, first_name: "Francis", last_name: "FACTICE", organisations: [org_mds]) }

    it "works (happy path)", js: true do
      login_as(agent_mds, scope: :agent)
      visit root_path
      within(".left-side-menu") { click_on "Trouver un RDV" }
      click_link "élargir votre recherche"
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
      expect(created_rdv.users.first.organisations).to match_array([org_mds, org_insertion])
      expect(created_rdv.organisation).to eq(org_insertion)
      expect(created_rdv.motif).to eq(motif_insertion)
      expect(created_rdv.lieu).to eq(mission_locale_paris_nord)
      expect(created_rdv.starts_at).to eq(Time.zone.parse("2024-02-05 11:00"))
      expect(created_rdv.created_by).to eq(agent_mds)
      expect(created_rdv.participations.last.created_by).to eq(agent_mds)
      expect(created_rdv.participations.last.created_by_agent_prescripteur).to eq(true)
    end

    it "works for a collective rdv", js: true do
      login_as(agent_mds, scope: :agent)
      visit root_path
      within(".left-side-menu") { click_on "Trouver un RDV" }
      click_link "élargir votre recherche"
      expect(page).to have_content("Nouveau RDV par prescription")
      # Select Service
      expect(page).to have_content("Sélectionnez le service avec qui vous voulez prendre un RDV")
      expect(page).to have_content(motif_collectif.service.name)
      find("h3", text: motif_collectif.service.name).ancestor("a").click
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
      expect(Rdv.last.participations.where(user: existing_user).first.created_by_agent_prescripteur).to eq(true)
    end
  end

  context "when creating a user along the way" do
    it "leaves the user both in local and distant organisation", js: true do
      login_as(agent_mds, scope: :agent)
      visit root_path
      within(".left-side-menu") { click_on "Trouver un RDV" }
      click_link "élargir votre recherche"
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
      expect(Rdv.last.users.first.organisations).to match_array([org_mds, org_insertion])
      expect(Rdv.last.participations.first.created_by_agent_prescripteur).to eq(true)
    end

    # Cette spec a été ajoutée suite à un bug qui faisait qu'on si on
    # revenait à l'étape de sélection usager et qu'on en créait un nouveau,
    # il n'était pas validé car le `user_ids` de l'ancien restant dans l'URL.
    it "allows going back to change the user", js: true do
      login_as(agent_mds, scope: :agent)
      visit root_path
      within(".left-side-menu") { click_on "Trouver un RDV" }
      click_link "élargir votre recherche"
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
      click_on "Continuer"
      expect { click_button "Confirmer le rdv" }.to change(Rdv, :count).by(1)
      expect(Rdv.last.users.first.full_name).to eq("Jean-Pierre BONJOUR")
      expect(Rdv.last.participations.first.created_by_agent_prescripteur).to eq(true)
    end
  end

  describe "when starting from a user profile" do
    let!(:user) { create(:user, organisations: [org_mds]) }

    it "pre-fills the user" do
      login_as(agent_mds, scope: :agent)
      visit admin_organisation_user_path(org_mds, id: user.id)
      within(".content") { click_on "Trouver un RDV" } # Trouver un RDV pour l'usager
      click_link "élargir votre recherche"
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
      expect(Rdv.last.participations.first.created_by_agent_prescripteur).to eq(true)
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
      login_as(agent_mds, scope: :agent)
      visit root_path
      within(".left-side-menu") { click_on "Trouver un RDV" }
      click_link "élargir votre recherche"
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
      expect(created_rdv.users.first.organisations).to match_array([organisation_mystere, org_insertion])
    end
  end
end
