RSpec.describe "Modification du nom et de la couleur d’affichage de la synchronisation CalDAV" do
  let(:agent) { create(:agent, :with_caldav_config) }
  let(:caldav_config) { agent.caldav_config }

  before do
    caldav_config.update!(caldav_calendar_name: "Ancien nom", caldav_calendar_color: "#111111")
    sign_in agent
  end

  describe "GET edit" do
    it "affiche le formulaire pré-rempli" do
      get edit_agents_calendar_sync_caldav_sync_path

      expect(response).to have_http_status(:ok)
      page = Capybara.string(response.body)
      expect(page.find("#caldav_config_caldav_calendar_name").value).to eq("Ancien nom")
      expect(page.find("#caldav_config_caldav_calendar_color").value).to eq("#111111")
    end

    context "quand aucune couleur n’est configurée" do
      before { caldav_config.update!(caldav_calendar_color: nil) }

      it "pré-remplit la couleur par défaut des indisponibilités" do
        get edit_agents_calendar_sync_caldav_sync_path

        color_input = Capybara.string(response.body).find("#caldav_config_caldav_calendar_color")
        expect(color_input.value).to eq(AbsencesHelper::CALENDAR_BACKGROUND_COLOR_HEX)
      end
    end

    context "quand l’agent n’a pas de configuration CalDAV" do
      let(:agent) { create(:agent) }
      let(:caldav_config) { create(:caldav_config, agent: create(:agent)) }

      it "redirige vers la page de configuration" do
        get edit_agents_calendar_sync_caldav_sync_path
        expect(response).to redirect_to(agents_calendar_sync_caldav_sync_path)
      end
    end

    context "quand la déconnexion est en cours" do
      before { caldav_config.update!(caldav_disconnect_started_at: Time.zone.now) }

      it "redirige vers la page de configuration" do
        get edit_agents_calendar_sync_caldav_sync_path
        expect(response).to redirect_to(agents_calendar_sync_caldav_sync_path)
      end
    end
  end

  describe "PATCH update_display" do
    it "met à jour le nom et la couleur sans relancer de synchronisation" do
      expect(Caldav::ImportAbsencesFromCaldavJob).not_to receive(:perform_later)
      expect(Caldav::MassExportEventToCaldavJob).not_to receive(:perform_later)

      patch update_display_agents_calendar_sync_caldav_sync_path, params: { caldav_config: { caldav_calendar_name: "Nouveau nom", caldav_calendar_color: "#3388ff" } }

      expect(response).to redirect_to(agents_calendar_sync_caldav_sync_path)
      expect(caldav_config.reload).to have_attributes(caldav_calendar_name: "Nouveau nom", caldav_calendar_color: "#3388ff")
      expect(flash[:success]).to eq("Les paramètres d’affichage de votre agenda CalDAV ont été mis à jour.")
    end

    it "ne permet pas de modifier les autres paramètres de connexion" do
      patch update_display_agents_calendar_sync_caldav_sync_path, params: {
        caldav_config: { caldav_calendar_name: "Nouveau nom", caldav_agenda_url: "https://pirate.example.com", caldav_include_sensitive_data: true },
      }

      expect(caldav_config.reload).to have_attributes(
        caldav_calendar_name: "Nouveau nom",
        caldav_agenda_url: "https://ox8-oidc.ox8-oidc.osprod.dimail1.numerique.gouv.fr/dav/caldav/1234_calendar_id",
        caldav_include_sensitive_data: false
      )
    end
  end
end
