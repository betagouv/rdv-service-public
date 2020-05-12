describe "Agent can create a Rdv with wizard" do
  include UsersHelper

  let!(:agent) { create(:agent, first_name: "Alain") }
  let!(:agent2) { create(:agent, first_name: "Robert") }
  let!(:motif) { create(:motif) }
  let!(:user) { create(:user) }

  before do
    travel_to(Time.zone.local(2019, 10, 2))
    login_as(agent, scope: :agent)
    visit new_organisation_rdv_wizard_step_path(organisation_id: agent.organisation_ids.first)
  end

  after { travel_back }

  scenario "default", js: true do
    # Step 1
    expect_page_title("Choisir le motif")

    select(motif.name, from: "rdv_motif_id")
    click_button('Continuer')

    # Step 2
    expect_page_title("Choisir le ou les usagers")
    expect_checked("Motif : #{motif.name}")
    select_user(user)
    click_link('Ajouter un autre usager')
    expect(page).to have_link('Créer un usager')
    click_link('Créer un usager')

    # create user with mail
    expect(find("#modal-holder")).to have_content("Nouvel usager")
    fill_in :user_first_name, with: "Jean-Paul"
    fill_in :user_last_name, with: "Orvoir"
    fill_in :user_email, with: "jporvoir@bidule.com"
    sleep(1) # wait for scroll to not interfere with form input
    page.execute_script "$('#mainModal').scrollTop(1000)"
    click_button('Créer usager')
    sleep(1) # wait for modal to hide completely

    # create user without email
    click_link('Ajouter un autre usager')
    click_link('Créer un usager')
    fill_in :user_first_name, with: "Jean-Marie"
    fill_in :user_last_name, with: "Lapin"
    sleep(1) # wait for scroll to not interfere with form input
    page.execute_script "$('#mainModal').scrollTop(1000)"
    click_button('Créer usager')
    sleep(1) # wait for modal to hide completely

    fill_in :rdv_notes, with: "RDV très spécial"
    click_button('Continuer')

    # Step 3
    expect_page_title("Choisir la durée et la date")
    expect_checked(motif.name)
    expect(page).to have_selector("input#rdv_duration_in_min[value='#{motif.default_duration_in_min}']")
    fill_in 'Lieu', with: "79 Rue de Plaisance, 92250 La Garenne-Colombes"
    fill_in 'Durée en minutes', with: '35'
    fill_in 'Commence à', with: '11/10/2019 14:15'

    select_agent(agent)
    select_agent(agent2)
    click_button('Créer RDV')

    expect(user.rdvs.count).to eq(1)
    rdv = user.rdvs.first
    expect(rdv.users.count).to eq(3)
    expect(rdv.motif).to eq(motif)
    expect(rdv.duration_in_min).to eq(35)
    expect(rdv.starts_at).to eq(Time.zone.local(2019, 10, 11, 14, 15))
    expect(rdv.created_by_agent?).to be(true)
    expect(rdv.notes).to eq("RDV très spécial")

    expect(page).to have_current_path(rdv.agenda_path_for_agent(agent))
    expect(page).to have_content("Votre agenda")
    sleep(0.5) # wait for ajax request
  end

  def select_agent(agent)
    select(agent.full_name_and_service, from: 'rdv_agent_ids')
  end

  def expect_checked(text)
    expect(page).to have_selector(".card .list-group-item", text: text)
  end
end
