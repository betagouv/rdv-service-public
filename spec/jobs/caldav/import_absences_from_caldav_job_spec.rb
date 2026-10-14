RSpec.describe Caldav::ImportAbsencesFromCaldavJob do
  let(:agent) { create(:agent, :with_caldav_config) }

  context "quand l'agent n'a pas de token et que la BDD est vide" do
    around do |example|
      VCR.use_cassette("caldav/token_via_propfind", allow_playback_repeats: true) do
        example.run
      end
    end

    it "crée une ligne ExternalCalendarEvent locale pour chaque événement et enregistre le token" do
      VCR.use_cassette("caldav/event_list_weekly_and_daily") do
        expect { described_class.new.perform(agent.id) }.to(
          change(ExternalCalendarEvent, :count).by(2).and(
            change { agent.caldav_config.reload.caldav_sync_token }.from(nil)
          )
        )
      end

      daily_event = ExternalCalendarEvent.where(
        url: "https://ox8-oidc.ox8-oidc.osprod.dimail1.numerique.gouv.fr/dav/caldav/1234_calendar_id/fa75d9fe-2063-465e-a323-dd8ae7589746.ics"
      ).sole
      expect(daily_event).to be_recurring
      expect(daily_event.agent_id).to eq(agent.id)
      expect(daily_event.raw_ical).to include("RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH")
      expect(daily_event.raw_ical).not_to include("SUMMARY:Daily") # scrubbed with Ical::Scrubber

      weekly_event = ExternalCalendarEvent.where(
        url: "https://ox8-oidc.ox8-oidc.osprod.dimail1.numerique.gouv.fr/dav/caldav/1234_calendar_id/6a54e0b7-93cf-43e4-a854-afd8e3d3f2c4.ics"
      ).sole
      expect(weekly_event).to be_recurring
      expect(daily_event.agent_id).to eq(agent.id)
      expect(weekly_event.raw_ical).to include("RRULE:FREQ=WEEKLY;BYDAY=TU")
      expect(daily_event.raw_ical).not_to include("SUMMARY:Weekly") # scrubbed with Ical::Scrubber
    end

    describe "gestion de TRANSP" do
      it "ignore un événement s'il est non récurrent et marqué TRANSP:TRANSPARENT" do
        VCR.use_cassette("caldav/transparent_event") do
          expect { described_class.new.perform(agent.id) }.not_to change(ExternalCalendarEvent, :count)
        end
      end

      it "ignore un événement s'il est récurrent et marqué TRANSP:TRANSPARENT" do
        VCR.use_cassette("caldav/transparent_recur_event") do
          expect { described_class.new.perform(agent.id) }.not_to change(ExternalCalendarEvent, :count)
        end
      end

      # Un événement récurrent
      it "enregistre un événement s'il est récurrent et marqué TRANSP:TRANSPARENT mais a au moins une exception opaque" do
        VCR.use_cassette("caldav/transparent_recur_event_with_one_opaque_exception") do
          expect { described_class.new.perform(agent.id) }.to change(ExternalCalendarEvent, :count).by(1)
        end
      end
    end

    it "ignore les événements sans DTEND (anniversaires, rappels...)" do
      VCR.use_cassette("caldav/event_without_dtend") do
        expect { described_class.new.perform(agent.id) }.not_to change(ExternalCalendarEvent, :count)
      end
    end

    it "ne crée pas d'événements si l'URL externe correspond à un Rdv local" do
      url_of_local_event = "https://ox8-oidc.ox8-oidc.osprod.dimail1.numerique.gouv.fr/dav/caldav/1234_calendar_id/fa75d9fe-2063-465e-a323-dd8ae7589746.ics"
      url_of_legit_event = "https://ox8-oidc.ox8-oidc.osprod.dimail1.numerique.gouv.fr/dav/caldav/1234_calendar_id/6a54e0b7-93cf-43e4-a854-afd8e3d3f2c4.ics"
      create(:agents_rdv, agent:, caldav_url: url_of_local_event)

      VCR.use_cassette("caldav/event_list_weekly_and_daily") do
        expect { described_class.new.perform(agent.id) }.to change(ExternalCalendarEvent, :count).by(1)
      end

      expect(ExternalCalendarEvent.pluck(:url)).to eq([url_of_legit_event])
    end
  end

  context "quand l’agent a un token et des événements en BDD" do
    around do |example|
      # TODO: on utilise pour le moment la cassette de création mais il faudrait faire une cassette dédiée
      VCR.use_cassette("caldav/token_via_propfind", allow_playback_repeats: true) do
        example.run
      end
    end

    let(:agent) { create(:agent, :with_caldav_config) }

    before { agent.caldav_config.update!(caldav_sync_token: "rsuneaitren") }

    it "supprime un événement s’il est déjà enregistré localement mais qu'il devient TRANSP:TRANSPARENT" do
      ExternalCalendarEvent.create(
        agent:,
        url: "https://ox8-oidc.ox8-oidc.osprod.dimail1.numerique.gouv.fr/dav/caldav/1234_calendar_id/c766aa62-c76e-48eb-a6a1-c5a496ec740b.ics",
        starts_at: Time.zone.tomorrow.change(hour: 9),
        ends_at: Time.zone.tomorrow.change(hour: 10)
      )

      VCR.use_cassette("caldav/transparent_event") do
        expect { described_class.new.perform(agent.id) }.to change(ExternalCalendarEvent, :count).by(-1)
        expect(ExternalCalendarEvent.where(url: "https://ox8-oidc.ox8-oidc.osprod.dimail1.numerique.gouv.fr/dav/caldav/1234_calendar_id/c766aa62-c76e-48eb-a6a1-c5a496ec740b.ics")).to be_empty
      end
    end

    context "quand le serveur Caldav retourne des VTODO dans l’appelle de sync" do
      it "ignore les VTODO et ne plante pas" do
        VCR.use_cassette("caldav/sync_with_vtodos") do
          expect { described_class.new.perform(agent.id) }.not_to raise_error
          expect(ExternalCalendarEvent.where(url: "https://ox8-oidc.ox8-oidc.osprod.dimail1.numerique.gouv.fr/dav/caldav/1234_calendar_id/vtodo_event.ics")).to be_empty
        end
      end
    end

    context "quand le serveur Caldav signale une suppression via un calendar_data vide (Suite Numérique)" do
      it "supprime l’événement local correspondant" do
        ExternalCalendarEvent.create(
          agent:,
          url: "https://ox8-oidc.ox8-oidc.osprod.dimail1.numerique.gouv.fr/dav/caldav/1234_calendar_id/event_signaled_as_deleted.ics",
          starts_at: Time.zone.tomorrow.change(hour: 9),
          ends_at: Time.zone.tomorrow.change(hour: 10)
        )

        VCR.use_cassette("caldav/sync_with_empty_calendar_data") do
          expect { described_class.new.perform(agent.id) }.to change(ExternalCalendarEvent, :count).by(-1)
        end

        expect(ExternalCalendarEvent.where(url: "https://ox8-oidc.ox8-oidc.osprod.dimail1.numerique.gouv.fr/dav/caldav/1234_calendar_id/event_signaled_as_deleted.ics")).to be_empty
      end
    end
  end

  describe "debounce du job" do
    around do |example|
      VCR.use_cassette("caldav/token_via_propfind", allow_playback_repeats: true) do
        VCR.use_cassette("caldav/no_event", allow_playback_repeats: true) do
          example.run
        end
      end
    end

    it "empêche d'enqueuer le même job s'il a été exécuté il y a moins d'une minute" do
      described_class.new.perform(agent.id)
      travel_to(10.seconds.from_now) { expect { described_class.perform_later(agent.id) }.not_to have_enqueued_job }
      travel_to(50.seconds.from_now) { expect { described_class.perform_later(agent.id) }.not_to have_enqueued_job }
      travel_to(70.seconds.from_now) { expect { described_class.perform_later(agent.id) }.to have_enqueued_job(described_class).with(agent.id) }
    end

    it "empêche d'exécuter le même job s'il a été exécuté il y a moins d'une minute" do
      agent_a = create(:agent, :with_caldav_config)
      agent_b = create(:agent, :with_caldav_config)

      # On enqueue un premier job pour un agent donné
      described_class.perform_later(agent_a.id)

      # On prévoit d'exécuter dans 2 secondes deux jobs: l'un pour le même agent et l'autre pour un agent différent.
      described_class.new(agent_a.id).enqueue(wait_until: 2.seconds.from_now)
      described_class.new(agent_b.id).enqueue(wait_until: 2.seconds.from_now)

      VCR.use_cassette("caldav/event_list_weekly_and_daily", allow_playback_repeats: true) do
        # On exécute le premier job uniquement, le second reste dans la queue
        perform_enqueued_jobs(at: Time.zone.now)
        expect(enqueued_jobs.size).to eq(2)

        travel_to(3.seconds.from_now) do
          # Le job pour le même agent ne s'exécute pas
          expect(Agent).not_to receive(:find).with(agent_a.id)
          # Le job pour l'autre agent s'exécute sans souci
          expect(Agent).to receive(:find).once.with(agent_b.id).and_call_original
          perform_enqueued_jobs
          expect(enqueued_jobs).to be_empty
        end
      end
    end
  end

  describe "logging de l'exécution" do
    around do |example|
      VCR.use_cassette("caldav/token_via_propfind", allow_playback_repeats: true) do
        example.run
      end
    end

    it "enregistre une exécution réussie avec ses messages" do
      VCR.use_cassette("caldav/event_list_weekly_and_daily") do
        expect { described_class.new.perform(agent.id) }.to change(ExternalCalendarSyncExecution, :count).by(1)
      end

      execution = ExternalCalendarSyncExecution.last
      expect(execution).to have_attributes(agent:, successful: true)
      expect(execution.ended_at).to be_present
      expect(execution.logs.pluck(:message)).to eq(
        ["First sync: loading all events (paginated)", "New/updated: 2, deleted : 0"]
      )
    end

    it "enregistre une exécution en échec avec le message d'erreur" do
      job = described_class.new
      allow(job).to receive(:update_local_events_of).and_raise(StandardError, "boom")

      VCR.use_cassette("caldav/event_list_weekly_and_daily") do
        expect { job.perform(agent.id) }.to raise_error(StandardError, "boom")
      end

      execution = ExternalCalendarSyncExecution.last
      expect(execution.successful).to be(false)
      expect(execution.logs.pluck(:message)).to include("Error: boom")
    end
  end

  # Zimbra ne supporte pas le report sync-collection (RFC 6578) et ne renvoie pas de sync-token.
  # On se base alors sur le ctag du calendrier pour savoir s'il a changé depuis la dernière synchro,
  # puis sur les etags des événements pour ne télécharger que ceux qui sont nouveaux ou modifiés.
  #
  # Les cassettes ont été enregistrées en deux temps sur un vrai serveur Zimbra :
  # - page 1 : 10 événements, ctag "1-32"
  # - page 2 : 6 événements ajoutés depuis, ctag "1-38"
  context "quand l'agent utilise un système ne supportant pas le sync token (Zimbra typiquement)" do
    # Toutes les requêtes (PROPFIND Depth 0 et 1, REPORT) visent l'URL du calendrier : on les distingue par leur body
    def with_zimbra_cassette(page, &)
      VCR.use_cassette("caldav/zimbra_without_sync_token_page_#{page}", match_requests_on: %i[method uri body], allow_playback_repeats: true, &)
    end

    before do
      agent.caldav_config.update!(
        caldav_agenda_url: "https://webmail.genci.fr/dav/pbrdv@genci.fr/Calendar",
        caldav_username: "pbrdv@genci.fr",
        # Le vrai mot de passe n’est utile que pour réenregistrer les cassettes
        caldav_password: ENV.fetch("ZIMBRA_CALDAV_PASSWORD", "mot_de_passe_factice")
      )
    end

    let(:url_of_event_deleted_on_server) { "https://webmail.genci.fr/dav/pbrdv%40genci.fr/Calendar/deleted-on-server.ics" }

    def sync_logs = ExternalCalendarSyncExecution.last.logs.pluck(:message)

    context "lors de la première synchro (page 1)" do
      around { |example| with_zimbra_cassette(1) { example.run } }

      it "importe tous les événements et enregistre le ctag et les etags" do
        expect { described_class.new.perform(agent.id) }.to change(ExternalCalendarEvent, :count).by(10)

        expect(agent.caldav_config.reload).to have_attributes(caldav_sync_token: nil, caldav_ctag: "1-32")
        expect(ExternalCalendarEvent.pluck(:etag)).to all(match(/\A"\d+-\d+"\z/))
        expect(sync_logs).to eq(["No sync token support: ctag changed, loading all events", "New/updated: 10, deleted : 0"])
      end

      it "supprime les événements locaux qui n'existent pas sur le serveur" do
        create(:external_calendar_event, agent:, url: url_of_event_deleted_on_server)

        described_class.new.perform(agent.id)

        expect(ExternalCalendarEvent.where(url: url_of_event_deleted_on_server)).to be_empty
        expect(ExternalCalendarEvent.count).to eq(10)
      end

      it "ne recharge pas les événements quand le ctag n'a pas changé" do
        agent.caldav_config.update!(caldav_ctag: "1-32")
        create(:external_calendar_event, agent:, url: url_of_event_deleted_on_server)

        expect { described_class.new.perform(agent.id) }.not_to change(ExternalCalendarEvent, :count)

        expect(sync_logs).to eq(["No sync token support: ctag unchanged, nothing to load", "New/updated: 0, deleted : 0"])
      end
    end

    context "lors d'une synchro suivante, après l'ajout d'événements sur le serveur (page 2)" do
      before do
        with_zimbra_cassette(1) { described_class.new.perform(agent.id) }
        create(:external_calendar_event, agent:, url: url_of_event_deleted_on_server, etag: '"22-22"')
      end

      it "ne télécharge que les nouveaux événements, sans toucher aux événements déjà synchronisés" do
        events_of_page_1 = ExternalCalendarEvent.where.not(url: url_of_event_deleted_on_server).order(:id).pluck(:id, :url, :etag)

        with_zimbra_cassette(2) do
          expect { described_class.new.perform(agent.id) }.to change(ExternalCalendarEvent, :count).from(11).to(16)
        end

        # Les événements de la page 1 sont toujours là, inchangés (ils n'ont été ni supprimés, ni recréés)
        expect(ExternalCalendarEvent.where(id: events_of_page_1.map(&:first)).order(:id).pluck(:id, :url, :etag)).to eq(events_of_page_1)
        # L'événement qui n'existe plus sur le serveur est supprimé
        expect(ExternalCalendarEvent.where(url: url_of_event_deleted_on_server)).to be_empty
        expect(agent.caldav_config.reload.caldav_ctag).to eq("1-38")
        expect(sync_logs).to eq(["No sync token support: ctag changed, loading only new or updated events", "New/updated: 6, deleted : 1"])
      end

      it "ne demande au serveur que les événements nouveaux ou modifiés" do
        urls_before_sync = ExternalCalendarEvent.pluck(:url)

        with_zimbra_cassette(2) { described_class.new.perform(agent.id) }

        multiget_requests = WebMock::RequestRegistry.instance.requested_signatures.hash.keys
          .select { _1.method == :report && _1.body.to_s.include?("calendar-multiget") }
        expect(multiget_requests.size).to eq(1)

        requested_hrefs = Nokogiri::XML(multiget_requests.first.body).xpath("//dav:href", "dav" => "DAV:").map(&:text)
        new_urls = ExternalCalendarEvent.pluck(:url) - urls_before_sync
        expect(requested_hrefs).to match_array(new_urls.map { URI(_1).path })
      end
    end
  end
end
