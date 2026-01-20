RSpec.describe Caldav::ImportAbsencesFromCaldavJob do
  it "works (creates local ExternalCalendarEvent rows for each event)" do
    agent = create(:agent, :with_caldav_config)

    VCR.use_cassette("caldav/daily_and_weekly") do
      expect do
        described_class.perform_later(agent.id)
        perform_enqueued_jobs
      end.to change(ExternalCalendarEvent, :count).by(2)

      # TODO: gérer les récurrences
      daily = {
        agent:,
        starts_at: Time.zone.parse("2026-01-13 09:45:00"),
        ends_at: Time.zone.parse("2026-01-13 10:15:00"),
        url: "https://ox8-oidc.ox8-oidc.osprod.dimail1.numerique.gouv.fr/dav/caldav/abcdef_this_is_calendar_id/fa75d9fe-2063-465e-a323-dd8ae7589746.ics",
      }
      expect(ExternalCalendarEvent.find_by(url: daily[:url])).to have_attributes(**daily)

      # TODO: gérer les récurrences
      weekly = {
        agent:,
        starts_at: Time.zone.parse("2026-01-13 11:00:00"),
        ends_at: Time.zone.parse("2026-01-13 12:00:00"),
        url: "https://ox8-oidc.ox8-oidc.osprod.dimail1.numerique.gouv.fr/dav/caldav/abcdef_this_is_calendar_id/6a54e0b7-93cf-43e4-a854-afd8e3d3f2c4.ics",
      }
      expect(ExternalCalendarEvent.find_by(url: weekly[:url])).to have_attributes(**weekly)
    end
  end
end
