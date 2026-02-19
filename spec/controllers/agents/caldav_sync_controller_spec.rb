RSpec.describe Agents::CaldavSyncController, type: :controller do
  let(:agent) { create(:agent) }
  let(:caldav_client) { instance_double(Calendav::Client) }
  let(:caldav_events) { instance_double(Calendav::Clients::EventsClient) }
  let(:caldav_calendars) { instance_double(Calendav::Clients::CalendarsClient) }

  let(:caldav_params) do
    {
      caldav_username: "user@example.fr",
      caldav_password: "secret",
      caldav_agenda_url: "https://caldav.example.fr/dav/calendars/user/default",
    }
  end

  before do
    sign_in agent
    allow_any_instance_of(Agent).to receive(:caldav_client).and_return(caldav_client) # rubocop:disable RSpec/AnyInstance
    allow(caldav_client).to receive(:principal_url).and_return("https://caldav.example.fr/dav/principals/user")
    allow(caldav_client).to receive(:events).and_return(caldav_events)
    allow(caldav_client).to receive(:calendars).and_return(caldav_calendars)
    allow(caldav_calendars).to receive(:find).and_return(double)
    allow(caldav_events).to receive(:create).and_return(instance_double(Calendav::Event, url: "https://caldav.example.fr/dav/calendars/user/default/test.ics"))
    allow(caldav_events).to receive(:delete)
  end

  describe "#show" do
    it "rend la page de configuration" do
      get :show
      expect(response).to have_http_status(:ok)
    end
  end

  describe "#update" do
    context "quand l’authentification, la lecture et l’écriture réussissent" do
      it "enregistre les identifiants et lance l’export en masse" do
        expect(Caldav::MassExportEventToCaldavJob).to receive(:perform_later).with(agent)

        put :update, params: caldav_params

        expect(response).to redirect_to(agents_calendar_sync_caldav_sync_path)
        expect(agent.reload.caldav_username).to eq("user@example.fr")
        expect(agent.reload.caldav_agenda_url).to eq("https://caldav.example.fr/dav/calendars/user/default")
      end

      it "ne met pas de message d’erreur en flash" do
        put :update, params: caldav_params
        expect(flash[:alert]).to be_nil
      end
    end

    context "quand l’authentification échoue" do
      before do
        allow(caldav_client).to receive(:principal_url).and_raise(StandardError.new("401 Unauthorized"))
      end

      it "affiche un message d’erreur d’authentification" do
        put :update, params: caldav_params

        expect(response).to redirect_to(agents_calendar_sync_caldav_sync_path)
        expect(flash[:alert]).to eq("L’authentification a échoué. Veuillez vérifier votre identifiant et votre mot de passe.")
      end

      it "ne sauvegarde pas les identifiants" do
        put :update, params: caldav_params
        expect(agent.reload.caldav_username).to be_nil
      end
    end

    context "quand la lecture du calendrier échoue" do
      before do
        allow(caldav_calendars).to receive(:find).and_raise(StandardError.new("404 Not Found"))
      end

      it "affiche un message d’erreur de lecture" do
        put :update, params: caldav_params

        expect(response).to redirect_to(agents_calendar_sync_caldav_sync_path)
        expect(flash[:alert]).to eq("L’accès en lecture au calendrier a échoué. Veuillez vérifier l’URL de l’agenda.")
      end

      it "ne sauvegarde pas les identifiants" do
        put :update, params: caldav_params
        expect(agent.reload.caldav_username).to be_nil
      end
    end

    context "quand l’écriture dans le calendrier échoue" do
      before do
        allow(caldav_events).to receive(:create).and_raise(StandardError.new("403 Forbidden"))
      end

      it "affiche un message d’erreur d’écriture" do
        put :update, params: caldav_params

        expect(response).to redirect_to(agents_calendar_sync_caldav_sync_path)
        expect(flash[:alert]).to eq("L’accès en écriture au calendrier a échoué. Veuillez vérifier vos droits d’accès à l’agenda.")
      end

      it "ne sauvegarde pas les identifiants" do
        put :update, params: caldav_params
        expect(agent.reload.caldav_username).to be_nil
      end
    end
  end

  describe "#destroy" do
    let(:agent) { create(:agent, :with_caldav_config) }

    it "active le flag de déconnexion et lance le job de nettoyage" do
      expect(Caldav::MassDestroyEventsAndAbsencesJob).to receive(:perform_later).with(agent)

      delete :destroy

      expect(response).to redirect_to(agents_calendar_sync_caldav_sync_path)
      expect(agent.reload.caldav_disconnect_in_progress).to be(true)
    end
  end
end
