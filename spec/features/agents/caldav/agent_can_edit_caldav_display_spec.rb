RSpec.describe "Modification du nom et de la couleur d’affichage de la synchronisation CalDAV" do
  let(:agent) { create(:agent, :with_caldav_config) }
  let(:caldav_config) { agent.caldav_config }

  before do
    caldav_config.update!(caldav_calendar_name: "Ancien nom", caldav_calendar_color: "#111111")
    login_as(agent, scope: :agent)
  end

  it "permet de modifier le nom et la couleur sans relancer de synchronisation" do
    expect(Caldav::ImportAbsencesFromCaldavJob).not_to receive(:perform_later)
    expect(Caldav::MassExportEventToCaldavJob).not_to receive(:perform_later)

    visit agents_calendar_sync_caldav_sync_path
    click_on "Modifier le nom et la couleur"

    expect(page).to have_field("Nom d’affichage de l’agenda", with: "Ancien nom")
    expect(page).to have_field("Couleur d’affichage de l’agenda", with: "#111111")

    fill_in "Nom d’affichage de l’agenda", with: "Nouveau nom"
    fill_in "Couleur d’affichage de l’agenda", with: "#3388ff"
    click_on "Enregistrer"

    expect(page).to have_current_path(agents_calendar_sync_caldav_sync_path)
    expect(page).to have_content("Les paramètres d’affichage de votre agenda CalDAV ont été mis à jour.")
    expect(page).to have_content("Nom d’affichage\nNouveau nom")
    expect(caldav_config.reload).to have_attributes(caldav_calendar_name: "Nouveau nom", caldav_calendar_color: "#3388ff")
  end

  context "quand aucune couleur n’est configurée" do
    before { caldav_config.update!(caldav_calendar_color: nil) }

    it "pré-remplit la couleur par défaut des indisponibilités" do
      visit edit_agents_calendar_sync_caldav_sync_path

      expect(page).to have_field("Couleur d’affichage de l’agenda", with: AbsencesHelper::CALENDAR_BACKGROUND_COLOR_HEX)
    end
  end

  context "quand l’agent n’a pas de configuration CalDAV" do
    let(:agent) { create(:agent) }
    let(:caldav_config) { create(:caldav_config, agent: create(:agent)) }

    it "redirige vers la page de configuration" do
      visit edit_agents_calendar_sync_caldav_sync_path

      expect(page).to have_current_path(agents_calendar_sync_caldav_sync_path)
    end
  end

  context "quand la déconnexion est en cours" do
    before { caldav_config.update!(caldav_disconnect_started_at: Time.zone.now) }

    it "redirige vers la page de configuration" do
      visit edit_agents_calendar_sync_caldav_sync_path

      expect(page).to have_current_path(agents_calendar_sync_caldav_sync_path)
    end
  end

  it "ne permet pas de modifier les autres paramètres de connexion" do
    page.driver.submit :patch, update_display_agents_calendar_sync_caldav_sync_path, {
      caldav_config: { caldav_calendar_name: "Nouveau nom", caldav_agenda_url: "https://pirate.example.com", caldav_include_sensitive_data: true },
    }

    expect(caldav_config.reload).to have_attributes(
      caldav_calendar_name: "Nouveau nom",
      caldav_agenda_url: "https://ox8-oidc.ox8-oidc.osprod.dimail1.numerique.gouv.fr/dav/caldav/1234_calendar_id",
      caldav_include_sensitive_data: false
    )
  end
end
