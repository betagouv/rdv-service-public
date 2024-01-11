describe "Agents can prescribe rdvs for a selected user" do
  let(:now) { Time.zone.parse("2024-01-05 16h00") }
  let!(:territory) { create(:territory, departement_number: "83") }
  let!(:organisation1) { create(:organisation, territory: territory) }
  let!(:organisation2) { create(:organisation, territory: territory) }
  let!(:agent) { create(:agent, admin_role_in_organisations: [organisation1]) }
  let!(:user) { create(:user, organisations: [organisation1]) }
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

  it "works, happy path", js: true do
    login_as(agent, scope: :agent)
    visit admin_organisation_agent_searches_path(organisation1, user_ids: [user.id])
    click_link "élargir votre recherche"
    expect(page).to have_content("Prescription")
    expect(page).to have_content("pour #{user.full_name}")
    # Select Service
    expect(page).to have_content("Sélectionnez le service avec qui vous voulez prendre un RDV")
    expect(page).to have_content(motif1.service.name)
    expect(page).to have_content(motif2.service.name)
    find("h3", text: motif1.service.name).click
    # Select Motif
    expect(page).to have_content("Sélectionnez le motif de votre RDV")
    expect(page).to have_content(motif1.name)
    expect(page).to have_content(motif2.name)
    find("h3", text: motif1.name).click
    # Select Lieu
    expect(page).to have_content(lieu1.name)
    expect(page).to have_content(lieu2.name)
    find(".card-title", text: /#{lieu1.name}/).ancestor(".card").find("a.stretched-link").click
    expect(page).to have_content(lieu1.name)
    # Select créneau
    first(:link, "11:00").click
    # Display Recapitulatif
    expect(page).to have_content("Motif : #{motif1.name}")
    expect(page).to have_content("Lieu : #{lieu1.name}")
    expect(page).to have_content("Date du rendez-vous :")
    expect(page).to have_content("Usager : #{user.full_name}")
    click_button "Confirmer le rdv"
    # Display Confirmation
    expect(page).to have_content("Rendez-vous confirmé")
    expect(Rdv.count).to eq(1)
    expect(Rdv.last.users.first).to eq(user)
    expect(Rdv.last.organisation).to eq(organisation1)
    expect(Rdv.last.motif).to eq(motif1)
    expect(Rdv.last.lieu).to eq(lieu1)
    expect(Rdv.last.starts_at).to eq(Time.zone.parse("2024-02-05 11:00"))
    expect(Rdv.last.created_by).to eq(agent)
    expect(Rdv.last.participations.last.created_by).to eq(agent)
  end
end
