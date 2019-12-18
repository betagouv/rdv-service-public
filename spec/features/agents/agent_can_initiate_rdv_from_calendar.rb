describe "Agent can initiate a Rdv from calendar" do
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
    # Step 1
    expect_page_title("Votre agenda")

    find('.fc-bgevent', match: :first).click

    select(motif.name, from: "rdv_motif_id")
    click_button('Continuer')

    expect(find(".select2")).to have_content(agent.full_name_and_service)
    expect(find(".select2")).not_to have_content(agent2.full_name_and_service)
  end

  scenario "for an other agent", js: true do
    select(agent2.full_name, from: 'id')

    # Step 1
    expect_page_title("Agenda de #{agent2.full_name_and_service}")

    find('.fc-bgevent', match: :first).click

    select(motif.name, from: "rdv_motif_id")
    click_button('Continuer')

    expect(find(".select2")).not_to have_content(agent.full_name_and_service)
    expect(find(".select2")).to have_content(agent2.full_name_and_service)
  end
end
