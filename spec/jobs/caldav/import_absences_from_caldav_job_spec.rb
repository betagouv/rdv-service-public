RSpec.describe Caldav::ImportAbsencesFromCaldavJob do
  let(:agent) { create(:agent, :with_caldav_config) }

  context "when agent does not have a token and DB is empty" do
    it "works creates local ExternalCalendarEvent row for each event and saves token" do
      described_class.perform_later(agent.id)
      VCR.use_cassette("caldav/initial_get_token_and_event_list") do
        expect { perform_enqueued_jobs }.to(
          change(ExternalCalendarEvent, :count).by(2).and(
            change { agent.reload.caldav_sync_token }.from(nil)
          )
        )
      end

      daily_event = ExternalCalendarEvent.where(
        url: "https://ox8-oidc.ox8-oidc.osprod.dimail1.numerique.gouv.fr/dav/caldav/1234_calendar_id/fa75d9fe-2063-465e-a323-dd8ae7589746.ics"
      ).sole
      expect(daily_event).to be_recurring
      expect(daily_event.raw_ical).to include("RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH")
      expect(daily_event.raw_ical).not_to include("SUMMARY:Daily") # scrubbed with Ical::Scrubber

      weekly_event = ExternalCalendarEvent.where(
        url: "https://ox8-oidc.ox8-oidc.osprod.dimail1.numerique.gouv.fr/dav/caldav/1234_calendar_id/6a54e0b7-93cf-43e4-a854-afd8e3d3f2c4.ics"
      ).sole
      expect(weekly_event).to be_recurring
      expect(weekly_event.raw_ical).to include("RRULE:FREQ=WEEKLY;BYDAY=TU")
      expect(daily_event.raw_ical).not_to include("SUMMARY:Weekly") # scrubbed with Ical::Scrubber
    end
  end

  it "prevents from enqueuing the same job if it ran less than a minute ago" do
    VCR.use_cassette("caldav/initial_get_token_and_event_list", allow_playback_repeats: true) do
      described_class.perform_now(agent.id)
      travel_to(10.seconds.from_now) { expect { described_class.perform_later(agent.id) }.not_to have_enqueued_job }
      travel_to(50.seconds.from_now) { expect { described_class.perform_later(agent.id) }.not_to have_enqueued_job }
      travel_to(70.seconds.from_now) { expect { described_class.perform_later(agent.id) }.to have_enqueued_job(described_class).with(agent.id) }
    end
  end

  it "prevents from performing the same job if it ran less than a minute ago" do
    agent_a = create(:agent, :with_caldav_config)
    agent_b = create(:agent, :with_caldav_config)

    # On exécute un premier job pour un agent donné
    described_class.perform_later(agent_a.id)

    # On prévoit d'exécuter dans 2 secondes deux jobs: l'un pour le même agent et l'autre pour un agent différent.
    described_class.new(agent_a.id).enqueue(wait_until: 2.seconds.from_now)
    described_class.new(agent_b.id).enqueue(wait_until: 2.seconds.from_now)

    VCR.use_cassette("caldav/initial_get_token_and_event_list", allow_playback_repeats: true) do
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
