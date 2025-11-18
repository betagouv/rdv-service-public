RSpec.describe "permettre de revenir à l'agenda d'un collègue après avoir cliqué sur un RDV pour le modifier" do
  let(:territory) { create(:territory, work_on_sunday: true) } # nécessaire pour lancer cette spec un dimanche
  let(:organisation) { create(:organisation, territory:) }
  let!(:current_agent) { create(:agent, first_name: "Agent", last_name: "COURANT", admin_role_in_organisations: [organisation], display_saturdays: true) }
  let!(:collegue) { create(:agent, first_name: "Mon", last_name: "COLLEGUE", admin_role_in_organisations: [organisation]) }
  let!(:usager_du_rdv) { create(:user, first_name: "Usager", last_name: "DU RDV") }
  let!(:rdv_du_collegue) do
    create(
      :rdv,
      :no_service,
      organisation:,
      starts_at: Time.zone.today.beginning_of_day + 8.hours,
      agents: [collegue],
      users: [usager_du_rdv]
    )
  end

  it "fonctionne quand j'ai un seul agent sélectionné dans l'agenda", js: true do
    login_as(current_agent, scope: :agent)

    visit admin_organisation_planning_agenda_path(organisation)
    find("#select2-planning_agent_select-container").click
    find(%(.select2-results__option), text: "COLLEGUE Mon").click
    expect(page).to have_content("Agenda de Mon COLLEGUE")
    click_on "Usager DU RDV" # on clique sur le RDV dans l'agenda

    expected_fil_ariane = "Agenda de Mon COLLEGUE  RDV Usager DU RDV"
    expect(page).to have_content(expected_fil_ariane)
    click_on "Modifier"
    expect(page).to have_content(expected_fil_ariane)
    fill_in "rdv_duration_in_min", with: "240"
    click_on "Enregistrer"
    click_on "Confirmer en ignorant les avertissements" if page.body.include?("Confirmer en ignorant les avertissements") # modification d'un RDV dans le passé
    expect(rdv_du_collegue.reload.duration_in_min).to eq(240)
    expect(page).to have_content(expected_fil_ariane)
    click_on "Agenda de Mon COLLEGUE"
    expect(page).to have_content("Agenda de Mon COLLEGUE")
  end

  it "fonctionne quand j'ai plusieurs agents sélectionnés dans l'agenda", js: true do
    current_agent.enable_feature!(Agent::FeatureFlags::NEW_PLANNING)
    login_as(current_agent, scope: :agent)

    visit admin_organisation_planning_agenda_path(organisation)
    click_on "Sélectionner plusieurs agents"
    find("#planning_agents_select .select2-container").click
    find(%(.select2-results__option), text: "COLLEGUE Mon").click
    find("#submit_agents").click
    click_on "Usager DU RDV" # on clique sur le RDV dans l'agenda

    expected_fil_ariane = "Agendas de M. COLLEGUE, A. COURANT  RDV Usager DU RDV"
    expect(page).to have_content(expected_fil_ariane)
    click_on "Modifier"
    expect(page).to have_content(expected_fil_ariane)
    fill_in "rdv_duration_in_min", with: "240"
    click_on "Enregistrer"
    click_on "Confirmer en ignorant les avertissements" if page.body.include?("Confirmer en ignorant les avertissements") # modification d'un RDV dans le passé
    expect(rdv_du_collegue.reload.duration_in_min).to eq(240)
    expect(page).to have_content(expected_fil_ariane)
    click_on "Agendas de M. COLLEGUE, A. COURANT"
    expect(page).to have_content("Revenir à mon agenda")
    expect(page).to have_current_path(admin_organisation_planning_agenda_path(organisation, agent_id: [collegue, current_agent]))
  end
end
