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
    successful_log = create(
      :external_calendar_sync_log,
      agent: agent,
      calendar_url: caldav_config.caldav_agenda_url,
      started_at: Time.zone.parse("2026-08-20 10:00:00"),
      ended_at: Time.zone.parse("2026-08-20 10:00:02"),
      successful: true,
      text_logs: ["Récupération de 3 événements", "Synchronisation terminée"]
    )
    failed_log = create(
      :external_calendar_sync_log,
      agent: agent,
      calendar_url: caldav_config.caldav_agenda_url,
      started_at: Time.zone.parse("2026-08-21 10:00:00"),
      ended_at: Time.zone.parse("2026-08-21 10:00:01"),
      successful: false,
      text_logs: ["Erreur d'authentification"]
    )
    # belongs to another agent: must not be displayed
    create(:external_calendar_sync_log, calendar_url: caldav_config.caldav_agenda_url)
    # same agent, but a different (previous) calendar: must not be displayed
    create(:external_calendar_sync_log, agent: agent, calendar_url: "https://old-calendar.example.com")

    login_as(agent, scope: :agent)
    visit agents_calendar_sync_logs_path

    expect(page).to have_css("table tbody tr", count: 2)

    within("#external_calendar_sync_log_#{successful_log.id}") do
      expect(page).to have_content(I18n.l(successful_log.started_at, format: :human))
      expect(page).to have_content("Succès")
      expect(page).to have_content("2000 ms")
      expect(page).to have_content("Récupération de 3 événements")
      expect(page).to have_content("Synchronisation terminée")
    end

    within("#external_calendar_sync_log_#{failed_log.id}") do
      expect(page).to have_content(I18n.l(failed_log.started_at, format: :human))
      expect(page).to have_content("Échec")
      expect(page).to have_content("1000 ms")
    end
  end
end
