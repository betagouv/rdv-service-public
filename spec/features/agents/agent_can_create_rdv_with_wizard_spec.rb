describe "Agent can create a Rdv with wizard" do
  let!(:agent) { create(:agent, first_name: "Alain") }
  let!(:agent2) { create(:agent, first_name: "Robert") }
  let!(:motif) { create(:motif) }
  let!(:user) { create(:user) }

  before do
    login_as(agent, scope: :agent)
    visit authenticated_agent_root_path
    click_link('Créer un rendez-vous')
  end

  scenario "default" do
    # Step 1
    expect_page_title("Choisir le motif")

    select(motif.name, from: "rdv_motif_id")
    click_button('Continuer')

    # Step 2
    expect_page_title("Choisir la durée et la date")
    expect_checked(motif.name)
    expect(page).to have_selector("input#rdv_duration_in_min[value='#{motif.default_duration_in_min}']")
    fill_in 'Lieu', with: "79 Rue de Plaisance, 92250 La Garenne-Colombes"
    fill_in 'Durée en minutes', with: '35'
    fill_in 'Commence à', with: '12/10/2019 à 14h15'

    select_agent(agent)
    select_agent(agent2)
    click_button('Continuer')

    # Step 3
    expect_page_title("Choisir l'usager")
    expect_checked("Motif : #{motif.name}")
    expect_checked("Lieu : 79 Rue de Plaisance, 92250 La Garenne-Colombes")
    expect_checked("Durée : 35 minutes")
    expect_checked("Professionnels : #{agent.full_name_and_service} et #{agent2.full_name_and_service}")
    expect_checked("Commence le : samedi 12 octobre 2019 à 14h15")

    select_user(user)

    click_button('Continuer')

    expect(user.rdvs.count).to eq(1)
    rdv = user.rdvs.first
    expect(rdv.users).to contain_exactly(user)
    expect(rdv.motif).to eq(motif)
    expect(rdv.duration_in_min).to eq(35)
    expect(rdv.starts_at).to eq(Time.zone.local(2019, 10, 12, 14, 15))
    expect(page).to have_current_path(rdv.agenda_path)
  end

  def select_agent(agent)
    select(agent.full_name_and_service, from: 'rdv_agent_ids')
  end

  def select_user(user)
    select(user.full_name, from: 'rdv_user_ids')
  end

  def expect_checked(text)
    expect(page).to have_selector(".card .list-group-item", text: text)
  end
end
