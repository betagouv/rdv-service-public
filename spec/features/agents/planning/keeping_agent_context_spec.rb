RSpec.describe "permettre de revenir à l'agenda d'un collègue après avoir cliqué sur un RDV pour le modifier" do
  let(:now) { Time.zone.parse("2026-04-14 07:00") }
  let(:territory) { create(:territory) }
  let(:organisation) { create(:organisation, territory:) }
  let!(:current_agent) { create(:agent, first_name: "Agent", last_name: "COURANT", admin_role_in_organisations: [organisation], display_saturdays: true) }
  let!(:collegue) { create(:agent, first_name: "Mon", last_name: "COLLEGUE", admin_role_in_organisations: [organisation]) }
  let!(:usager_du_rdv) { create(:user, first_name: "Usager", last_name: "DU RDV") }
  let!(:rdv_du_collegue) do
    create(
      :rdv,
      :no_service,
      organisation:,
      starts_at: now.change(hour: 8),
      agents: [collegue],
      users: [usager_du_rdv]
    )
  end

  before do
    travel_to(now)
    page.driver.with_playwright_page { it.clock.set_fixed_time(now) }
  end

  it "fonctionne quand j'ai un seul agent sélectionné dans l'agenda", js: true do
    login_as(current_agent, scope: :agent)

    visit admin_organisation_planning_agenda_path(organisation)
    find("#select2-agent_id-container").click
    find(%(.select2-results__option), text: "COLLEGUE Mon").click
    click_on "Usager DU RDV" # on clique sur le RDV dans l'agenda

    back_button = "Retour à l'agenda de Mon COLLEGUE"
    expect(page).to have_link(back_button)
    click_on "Modifier"
    expect(page).to have_link(back_button)
    fill_in "rdv_duration_in_min", with: "240"
    click_on "Enregistrer"
    expect(page).to have_content("Le rendez-vous a été modifié.")
    expect(rdv_du_collegue.reload.duration_in_min).to eq(240)
    expect(page).to have_link(back_button)
    click_on back_button
    expect(page).to have_content("Planning de\nCOLLEGUE Mon")
  end

  it "fonctionne quand j'ai plusieurs agents sélectionnés dans l'agenda", js: true do
    login_as(current_agent, scope: :agent)

    visit admin_organisation_planning_agenda_path(organisation)
    click_on "Sélectionner plusieurs agents"
    find("#planning_agents_select .select2-container").click
    find(%(.select2-results__option), text: "COLLEGUE Mon").click
    find("#submit_agents").click
    click_on "Usager DU RDV" # on clique sur le RDV dans l'agenda

    back_button = "Retour aux agendas de M. COLLEGUE et A. COURANT"
    expect(page).to have_link(back_button)
    click_on "Modifier"
    expect(page).to have_link(back_button)
    fill_in "rdv_duration_in_min", with: "240"
    click_on "Enregistrer"
    expect(page).to have_content("Le rendez-vous a été modifié.")
    expect(rdv_du_collegue.reload.duration_in_min).to eq(240)
    expect(page).to have_link(back_button)
    click_on back_button
    expect(page).to have_content("Revenir à mon agenda")
    expect(page).to have_current_path(admin_organisation_planning_agenda_path(organisation, agent_id: [collegue, current_agent]))
  end
end
