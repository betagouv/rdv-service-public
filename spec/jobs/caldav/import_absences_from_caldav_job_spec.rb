RSpec.describe Caldav::ImportAbsencesFromCaldavJob do
  it "works (creates local ExternalCalendarEvent rows for each event)" do
    agent = create(
      :agent,
      caldav_agenda_url: "https://ox8-oidc.ox8-oidc.osprod.dimail1.numerique.gouv.fr/dav/caldav/Y2FsOi8vMC8xMzk2Ng",
      caldav_username: "francois.ferrandis.ext@beta.gouv.fr",
      caldav_password: "fake_password"
    )

    VCR.use_cassette("caldav/daily_and_weekly") do
      perform_enqueued_jobs do
        expect { described_class.perform_later(agent.id) }.to change(ExternalCalendarEvent, :count).by(29)
      end
    end

    occurrences_of_daily_event = ExternalCalendarEvent.where(
      url: "https://ox8-oidc.ox8-oidc.osprod.dimail1.numerique.gouv.fr/dav/caldav/Y2FsOi8vMC8xMzk2Ng/fa75d9fe-2063-465e-a323-dd8ae7589746.ics"
    )

    expected_daily_occurrences = %w[
      2026-01-13
      2026-01-14
      2026-01-15
      2026-01-19
      2026-01-20
      2026-01-21
      2026-01-22
      2026-01-26
      2026-01-27
      2026-01-28
      2026-01-29
      2026-02-02
      2026-02-03
      2026-02-04
      2026-02-05
      2026-02-09
      2026-02-10
      2026-02-11
      2026-02-12
      2026-02-16
      2026-02-17
      2026-02-18
      2026-02-19
    ]

    expect(occurrences_of_daily_event.pluck(:starts_at).map(&:to_date).map(&:to_s)).to eq(expected_daily_occurrences)

    occurrences_of_weekly_event = ExternalCalendarEvent.where(
      url: "https://ox8-oidc.ox8-oidc.osprod.dimail1.numerique.gouv.fr/dav/caldav/Y2FsOi8vMC8xMzk2Ng/6a54e0b7-93cf-43e4-a854-afd8e3d3f2c4.ics"
    )
    expected_weekly_occurrences = %w[
      2026-01-13
      2026-01-20
      2026-01-27
      2026-02-03
      2026-02-10
      2026-02-17
    ]
    expect(occurrences_of_weekly_event.pluck(:starts_at).map(&:to_date).map(&:to_s)).to eq(expected_weekly_occurrences)
  end
end
