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
            change { agent.reload.caldav_sync_token }.from(nil)
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

    let(:agent) { create(:agent, :with_caldav_config, caldav_sync_token: "rsuneaitren") }

    it "supprime un événement s’il est déjà enregistré localement mais qu'il devient TRANSP:TRANSPARENT" do
      ExternalCalendarEvent.create(
        agent:,
        url: "https://ox8-oidc.ox8-oidc.osprod.dimail1.numerique.gouv.fr/dav/caldav/1234_calendar_id/c766aa62-c76e-48eb-a6a1-c5a496ec740b.ics",
        starts_at: Time.zone.tomorrow.change(hour: 9, min: 0),
        ends_at: Time.zone.tomorrow.change(hour: 10, min: 0)
      )

      VCR.use_cassette("caldav/transparent_event") do
        expect { described_class.new.perform(agent.id) }.to change(ExternalCalendarEvent, :count).by(-1)
        expect(ExternalCalendarEvent.where(url: "https://ox8-oidc.ox8-oidc.osprod.dimail1.numerique.gouv.fr/dav/caldav/1234_calendar_id/c766aa62-c76e-48eb-a6a1-c5a496ec740b.ics")).to be_empty
      end
    end
  end

  it "enregistre la réponse dans Sentry si la récupération du token retourne un body inattendu" do
    cal_url = "https://ox8-oidc.ox8-oidc.osprod.dimail1.numerique.gouv.fr/dav/caldav/1234_calendar_id"
    stub_request(:propfind, cal_url)
      .and_return({ status: 500, body: "ceci est mon corps", headers: { "Set-Cookie" => "secret" } })

    described_class.perform_now(agent.id)

    expect(sentry_events.last.exception.values.last.value).to eq("500 Internal Server Error (Calendav::RequestError)")

    request_breadcrumb = sentry_events.last.breadcrumbs.compact[0]
    expect(request_breadcrumb.data[:method]).to eq(:propfind)
    expect(request_breadcrumb.data[:url]).to eq(cal_url)
    expect(request_breadcrumb.data[:headers]["Authorization"]).to eq("[FILTERED]")

    response_breadcrumb = sentry_events.last.breadcrumbs.compact[1]
    expect(response_breadcrumb.data[:status_code]).to eq(500)
    expect(response_breadcrumb.data[:body]).to eq("ceci est mon corps")
    expect(response_breadcrumb.data[:duration_ms]).to be_within(50).of(50) # entre 0 et 100ms
    expect(response_breadcrumb.data[:headers]["Set-Cookie"]).to eq("[FILTERED]")
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
end
