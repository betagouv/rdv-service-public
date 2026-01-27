FactoryBot.define do
  factory :external_calendar_event do
    agent { association(:agent) }
    url { "https://ox8-oidc.ox8-oidc.osprod.dimail1.numerique.gouv.fr/dav/caldav/1234_calendar_id/#{SecureRandom.uuid}.ics" }
    starts_at { Time.zone.today.at(Tod::TimeOfDay.parse("09:00")) }
    ends_at { Time.zone.today.at(Tod::TimeOfDay.parse("11:00")) }
  end

  trait :recurring_on_weekdays do
    raw_ical do
      <<~ICALENDAR
        BEGIN:VCALENDAR
        VERSION:2.0
        BEGIN:VEVENT
        DTEND;TZID=Europe/Paris:20181215T100000
        DTSTART;TZID=Europe/Paris:20181215T094500
        RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR
        SUMMARY:Daily
        TRANSP:OPAQUE
        UID:20c37ba2-34a4-47ea-8461-9876914904c6
        END:VEVENT
        END:VCALENDAR
      ICALENDAR
    end
  end
end
