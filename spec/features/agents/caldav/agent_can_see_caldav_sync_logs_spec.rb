RSpec.describe "Agent can see CalDAV sync logs" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let!(:caldav_config) { create(:caldav_config, agent: agent) }

  it "displays a link to the logs index" do
    login_as(agent, scope: :agent)
    visit agents_calendar_sync_caldav_sync_path

    click_on "l'historique de synchro"

    expect(page).to have_current_path(agents_calendar_sync_logs_path)
    expect(page).to have_content("Historique des synchronisations")
  end

  it "lists the logs" do
    successful_execution = create(
      :external_calendar_sync_execution,
      agent: agent,
      calendar_url: caldav_config.caldav_agenda_url,
      started_at: Time.zone.parse("2026-08-20 10:00:00"),
      ended_at: Time.zone.parse("2026-08-20 10:00:02"),
      successful: true
    )
    create(:external_calendar_sync_execution_log, external_calendar_sync_execution: successful_execution, message: "Récupération de 3 événements")
    create(:external_calendar_sync_execution_log, external_calendar_sync_execution: successful_execution, message: "Synchronisation terminée")

    failed_execution = create(
      :external_calendar_sync_execution,
      agent: agent,
      calendar_url: caldav_config.caldav_agenda_url,
      started_at: Time.zone.parse("2026-08-21 10:00:00"),
      ended_at: Time.zone.parse("2026-08-21 10:00:01"),
      successful: false
    )
    create(:external_calendar_sync_execution_log, external_calendar_sync_execution: failed_execution, message: "Erreur d'authentification")

    # belongs to another agent: must not be displayed
    create(:external_calendar_sync_execution, calendar_url: caldav_config.caldav_agenda_url)
    # same agent, but a different (previous) calendar: must not be displayed
    create(:external_calendar_sync_execution, agent: agent, calendar_url: "https://old-calendar.example.com")

    login_as(agent, scope: :agent)
    visit agents_calendar_sync_logs_path

    expect(page).to have_css("table tbody tr", count: 2)

    within("#external_calendar_sync_execution_#{successful_execution.id}") do
      expect(page).to have_content(I18n.l(successful_execution.started_at, format: :human))
      expect(page).to have_content("Succès")
      expect(page).to have_content("2000 ms")
      expect(page).to have_content("Récupération de 3 événements")
      expect(page).to have_content("Synchronisation terminée")
    end

    within("#external_calendar_sync_execution_#{failed_execution.id}") do
      expect(page).to have_content(I18n.l(failed_execution.started_at, format: :human))
      expect(page).to have_content("Échec")
      expect(page).to have_content("1000 ms")
    end
  end
end
