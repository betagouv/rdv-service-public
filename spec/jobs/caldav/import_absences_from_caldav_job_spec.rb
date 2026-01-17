RSpec.describe Caldav::ImportAbsencesFromCaldavJob do
  it "works (creates local ExternalCalendarEvent rows for each event)" do
    agent = create(:agent, :with_caldav_config)

    VCR.use_cassette("caldav/daily_and_weekly") do
      expect do
        described_class.perform_later(agent.id)
        perform_enqueued_jobs
      end.to change(ExternalCalendarEvent, :count).by(2)

      url = "https://ox8-oidc.ox8-oidc.osprod.dimail1.numerique.gouv.fr/dav/caldav/abcdef_this_is_calendar_id/fa75d9fe-2063-465e-a323-dd8ae7589746.ics"
      expect(ExternalCalendarEvent.find_by!(url:)).to have_attributes(agent:, starts_at: Time.zone.parse("2026-01-13 09:45:00"), ends_at: Time.zone.parse("2026-01-13 10:15:00"))
    end
  end
end
