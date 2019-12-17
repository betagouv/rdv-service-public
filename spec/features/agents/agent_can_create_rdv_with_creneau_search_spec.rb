describe "Agent can create a Rdv with creneau search" do
  include UsersHelper

  let!(:agent) { create(:agent, first_name: "Alain", last_name: "Tiptop") }
  let!(:agent2) { create(:agent, first_name: "Robert", last_name: "Voila") }
  let!(:agent3) { create(:agent, first_name: "Michel", last_name: "Lapin") }
  let!(:motif) { create(:motif, online: true) }
  let!(:user) { create(:user) }
  let!(:lieu) { create(:lieu) }
  let!(:plage_ouverture) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu, agent: agent) }
  let!(:lieu2) { create(:lieu) }
  let!(:plage_ouverture2) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu2, agent: agent2) }
  let!(:plage_ouverture3) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu, agent: agent3) }

  before do
    travel_to(Time.zone.local(2019, 7, 22))
    login_as(agent, scope: :agent)
    visit authenticated_agent_root_path

    expect(user.rdvs.count).to eq(0)
    click_link('Trouver un créneau')
  end

  after { travel_back }

  scenario "default", js: true do
    expect_page_title("Choisir un créneau")
    select(motif.name, from: "creneau_agent_search_motif_id")
    click_button('Afficher les créneaux')

    # Display results for both lieux
    expect(page).to have_content(plage_ouverture.lieu.address)
    expect(page).to have_content(plage_ouverture2.lieu.address)
    expect(page).to have_content(plage_ouverture.agent.short_name)
    expect(page).to have_content(plage_ouverture2.agent.short_name)

    # Add a filter on lieu
    select(lieu.name, from: "creneau_agent_search_lieu_ids")
    click_button('Afficher les créneaux')
    expect(page).to have_content(plage_ouverture.lieu.address)
    expect(page).not_to have_content(plage_ouverture2.lieu.address)

    # Add an agent filter
    select(agent.full_name, from: "creneau_agent_search_agent_ids")
    click_button('Afficher les créneaux')
    expect(page).to have_content(plage_ouverture.agent.short_name)
    expect(page).not_to have_content(plage_ouverture2.agent.short_name)

    # Click to change to next week
    first(:link, ">>").click
    expect(page).to have_content('<<', wait: 5)

    expect(page).to have_content(plage_ouverture.agent.short_name)
    expect(page).not_to have_content(plage_ouverture2.agent.short_name)
    expect(page).not_to have_content(plage_ouverture3.agent.short_name)

    # Select creneau
    first(:link, "09:30").click

    # Step 3
    expect_page_title("Choisir l'usager")
    expect_checked("Motif : #{motif.name}")
    expect_checked("Lieu : #{lieu.address}")
    expect_checked("Durée : #{motif.default_duration_in_min} minutes")
    expect_checked("Professionnels : #{agent.full_name_and_service}")

    select_user(user)

    click_button('Continuer')

    expect(user.rdvs.count).to eq(1)
    rdv = user.rdvs.first
    expect(rdv.users).to contain_exactly(user)
    expect(rdv.motif).to eq(motif)
    expect(rdv.duration_in_min).to eq(motif.default_duration_in_min)

    expect(page).to have_content("Le rendez-vous a été créé.")
    expect(page).to have_current_path(rdv.agenda_path_for_agent(agent))
    expect(page).to have_content("29 JUIL. – 2 AOÛT 2019")
  end

  def select_user(user)
    find(:css, ".select2-search__field").set(user.full_name)
    sleep(0.5)
    expect(page).to have_content(full_name_and_birthdate(user))
    find('.select2-search__field').native.send_keys(:return)
  end

  def expect_checked(text)
    expect(page).to have_selector(".card .list-group-item", text: text)
  end
end
