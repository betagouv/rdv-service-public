describe "Agents can prescribe rdvs" do
  let(:now) { Time.zone.parse("2024-01-05 16h00") }
  let!(:territory) { create(:territory, departement_number: "83") }
  let!(:organisation1) { create(:organisation, territory: territory) }
  let!(:organisation2) { create(:organisation, territory: territory) }
  let!(:agent) { create(:agent, admin_role_in_organisations: [organisation1]) }
  let!(:motif1) { create(:motif, organisation: organisation1, service: agent.services.first) }
  let!(:motif2) { create(:motif, organisation: organisation2, service: agent.services.first) }
  let!(:motif3) { create(:motif, organisation: organisation2) }
  let!(:lieu1) { create(:lieu, organisation: organisation1) }
  let!(:lieu2) { create(:lieu, organisation: organisation1) }
  let!(:lieu_org2) { create(:lieu, organisation: organisation1) }
  let!(:plage_ouverture1) { create(:plage_ouverture, :daily, first_day: (now + 1.month).to_date, motifs: [motif1], lieu: lieu1, organisation: organisation1) }
  let!(:plage_ouverture2) { create(:plage_ouverture, :daily, first_day: (now + 1.month).to_date, motifs: [motif1], lieu: lieu2, organisation: organisation1) }
  let!(:plage_ouverture3) { create(:plage_ouverture, :daily, first_day: (now + 1.month).to_date, motifs: [motif2], lieu: lieu_org2, organisation: organisation2) }
  let!(:plage_ouverture4) { create(:plage_ouverture, :daily, first_day: (now + 1.month).to_date, motifs: [motif3], lieu: lieu_org2, organisation: organisation2) }

  before do
    stub_request(
      :get,
      "https://api-adresse.data.gouv.fr/search/?q=20%20avenue%20de%20S%C3%A9gur,%20Paris"
    ).to_return(status: 200, body: file_fixture("geocode_result.json").read, headers: {})
  end

  describe 'using "Trouver un RDV"' do
    let!(:existing_user) { create(:user, first_name: "Francis", last_name: "FACTICE", organisations: [organisation1]) }

    it "works (happy path)", js: true do
      login_as(agent, scope: :agent)
      visit root_path
      within(".left-side-menu") { click_on "Trouver un RDV" }
      click_link "élargir votre recherche"
      expect(page).to have_content("Prescription")
      # Select Service
      expect(page).to have_content("Sélectionnez le service avec qui vous voulez prendre un RDV")
      expect(page).to have_content(motif1.service.name)
      expect(page).to have_content(motif2.service.name)
      find("h3", text: motif1.service.name).ancestor("a").click
      # Select Motif
      expect(page).to have_content("Sélectionnez le motif de votre RDV")
      expect(page).to have_content(motif1.name)
      expect(page).to have_content(motif2.name)
      find("h3", text: motif1.name).ancestor("a").click
      # Select Lieu
      expect(page).to have_content(lieu1.name)
      expect(page).to have_content(lieu2.name)
      find(".card-title", text: /#{lieu1.name}/).ancestor(".card").find("a.stretched-link").click
      expect(page).to have_content(lieu1.name)
      # Select créneau
      first(:link, "11:00").click
      # Display User selection
      find(".select2-selection[aria-labelledby=select2-user_ids_-container]").click
      find(".select2-search__field").send_keys("francis")
      expect(page).to have_content("FACTICE Francis")
      first(".select2-results ul.select2-results__options li").click
      click_on "Continuer"
      # Display Récapitulatif
      expect(page).to have_content("Motif : #{motif1.name}")
      expect(page).to have_content("Lieu : #{lieu1.name}")
      expect(page).to have_content("Date du rendez-vous :")
      expect(page).to have_content("Usager : Francis FACTICE")
      click_button "Confirmer le rdv"
      # Display Confirmation
      expect(page).to have_content("Rendez-vous confirmé")
      expect(Rdv.count).to eq(1)
      created_rdv = Rdv.last
      expect(created_rdv.users.first).to eq(existing_user)
      expect(created_rdv.organisation).to eq(organisation1)
      expect(created_rdv.motif).to eq(motif1)
      expect(created_rdv.lieu).to eq(lieu1)
      expect(created_rdv.starts_at).to eq(Time.zone.parse("2024-02-05 11:00"))
      expect(created_rdv.created_by).to eq(agent)
      expect(created_rdv.participations.last.created_by).to eq(agent)
    end
  end

  describe "when starting from a user profile" do
    let!(:user) { create(:user, organisations: [organisation1]) }

    it "pre-fills the user" do
      login_as(agent, scope: :agent)
      visit admin_organisation_user_path(organisation1, id: user.id)
      within(".content") { click_on "Trouver un RDV" } # Trouver un RDV pour l'usager
      click_link "élargir votre recherche"
      expect(page).to have_content("Prescription")
      expect(page).to have_content("pour #{user.full_name}")
      # Select Service
      find("h3", text: motif1.service.name).ancestor("a").click
      # Select Motif
      expect(page).to have_content("Sélectionnez le motif de votre RDV")
      find("h3", text: motif1.name).ancestor("a").click
      # Select Lieu
      find(".card-title", text: /#{lieu1.name}/).ancestor(".card").find("a.stretched-link").click
      expect(page).to have_content(lieu1.name)
      # Select créneau
      first(:link, "11:00").click
      # Display Récapitulatif
      click_button "Confirmer le rdv"
      # Display Confirmation
      expect(page).to have_content("Rendez-vous confirmé")
      expect(Rdv.count).to eq(1)
      expect(Rdv.last.users.first).to eq(user)
    end
  end
end
