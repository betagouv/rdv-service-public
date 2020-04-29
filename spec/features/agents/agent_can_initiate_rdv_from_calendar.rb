describe "Agent can initiate a Rdv from calendar" do
  include UsersHelper

  let!(:agent) { create(:agent, :admin, first_name: "Alain") }
  let!(:agent2) { create(:agent, first_name: "Robert") }
  let!(:plage_ouverture) { create(:plage_ouverture, :weekly, agent: agent) }
  let!(:motif) { create(:motif) }
  let!(:user) { create(:user) }

  before do
    login_as(agent, scope: :agent)
    visit authenticated_agent_root_path
  end

  scenario "for him", js: true do
    expect_page_title("Votre agenda")

    initiate_rdv(agent)
  end

  scenario "for an other agent", js: true do
    select(agent2.full_name, from: 'id')
    expect_page_title("Agenda de #{agent2.full_name_and_service}")

    initiate_rdv(agent2)
  end

  def initiate_rdv(agent)
    # Step 1
    find('.fc-bgevent', match: :first).click

    # Step 2
    select(motif.name, from: "rdv_motif_id")
    click_button('Continuer')

    # Step 3
    expect(find(".select2")).to have_content(agent.full_name_and_service)
    click_button('Continuer')

    # Step 4
    select_user(user)
    expect(page).to have_content(full_name_and_birthdate(user))
    click_button('Continuer')

    # Step 5
    expect(page).to have_content("Le rendez-vous a été créé.")
  end
end
