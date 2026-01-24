RSpec.describe Caldav::ImportAbsencesFromCaldavJob do
  context "when agent does not have a token and DB is empty" do
    it "works creates local ExternalCalendarEvent row for each event and saves token" do
      agent = create(
        :agent,
        caldav_agenda_url: "https://ox8-oidc.ox8-oidc.osprod.dimail1.numerique.gouv.fr/dav/caldav/Y2FsOi8vMC8xMzk2Ng",
        caldav_username: "francois.ferrandis.ext@beta.gouv.fr",
        caldav_password: "fake_password"
      )

      described_class.perform_later(agent.id)
      VCR.use_cassette("caldav/daily_and_weekly") do
        expect { perform_enqueued_jobs }.to(
          change(ExternalCalendarEvent, :count).by(2).and(
            change { agent.reload.caldav_sync_token }.from(nil)
          )
        )
      end

      daily_event = ExternalCalendarEvent.where(
        url: "https://ox8-oidc.ox8-oidc.osprod.dimail1.numerique.gouv.fr/dav/caldav/Y2FsOi8vMC8xMzk2Ng/fa75d9fe-2063-465e-a323-dd8ae7589746.ics"
      ).sole
      expect(daily_event).to be_recurring
      expect(daily_event.raw_ical).to include("RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH")
      expect(daily_event.raw_ical).not_to include("SUMMARY:Daily") # scrubbed with Ical::Scrubber

      weekly_event = ExternalCalendarEvent.where(
        url: "https://ox8-oidc.ox8-oidc.osprod.dimail1.numerique.gouv.fr/dav/caldav/Y2FsOi8vMC8xMzk2Ng/6a54e0b7-93cf-43e4-a854-afd8e3d3f2c4.ics"
      ).sole
      expect(weekly_event).to be_recurring
      expect(weekly_event.raw_ical).to include("RRULE:FREQ=WEEKLY;BYDAY=TU")
      expect(daily_event.raw_ical).not_to include("SUMMARY:Weekly") # scrubbed with Ical::Scrubber
    end
  end
end
