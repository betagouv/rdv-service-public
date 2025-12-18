RSpec.describe Caldav::RruleExpander do
  describe "one time event" do
    let(:ponctuel) do
      <<~ICALENDAR
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Open-Xchange//8.43.61//EN
        BEGIN:VTIMEZONE
        TZID:Europe/Paris
        LAST-MODIFIED:20250410T142247Z
        TZURL:https://www.tzurl.org/zoneinfo-outlook/Europe/Paris
        X-LIC-LOCATION:Europe/Paris
        BEGIN:DAYLIGHT
        TZNAME:CEST
        TZOFFSETFROM:+0100
        TZOFFSETTO:+0200
        DTSTART:19700329T020000
        RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU
        END:DAYLIGHT
        BEGIN:STANDARD
        TZNAME:CET
        TZOFFSETFROM:+0200
        TZOFFSETTO:+0100
        DTSTART:19701025T030000
        RRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=-1SU
        END:STANDARD
        END:VTIMEZONE
        BEGIN:VEVENT
        DTSTAMP:20251218T130629Z
        CLASS:PUBLIC
        CREATED:20251217T112357Z
        DTEND;TZID=Europe/Paris:20251218T150000
        DTSTART;TZID=Europe/Paris:20251218T140000
        LAST-MODIFIED:20251218T130629Z
        PRIORITY:0
        SEQUENCE:4
        SUMMARY:Un truc ponctuel
        TRANSP:OPAQUE
        UID:a1124aab-8291-4613-ba68-a4710609cdec
        END:VEVENT
        END:VCALENDAR
      ICALENDAR
    end

    it "return the only occurrence" do
      from =  Time.zone.parse("2025-12-18 00:00")
      to =    Time.zone.parse("2025-12-28 23:59")
      expected_recurrences = [
        Recurrence::Occurrence.new(
          starts_at: Time.zone.parse("2025-12-18 14:00 +0100"),
          ends_at: Time.zone.parse("2025-12-18 15:00 +0100")
        ),
      ]
      actual_reccurrences = described_class.call(ical_calendar: ponctuel, from:, to:)
      expect(actual_reccurrences).to match(expected_recurrences)
    end
  end

  describe "daily event" do
    let(:every_day) do
      <<~ICALENDAR
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Open-Xchange//8.43.61//EN
        BEGIN:VTIMEZONE
        TZID:Europe/Paris
        LAST-MODIFIED:20250410T142247Z
        TZURL:https://www.tzurl.org/zoneinfo-outlook/Europe/Paris
        X-LIC-LOCATION:Europe/Paris
        BEGIN:DAYLIGHT
        TZNAME:CEST
        TZOFFSETFROM:+0100
        TZOFFSETTO:+0200
        DTSTART:19700329T020000
        RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU
        END:DAYLIGHT
        BEGIN:STANDARD
        TZNAME:CET
        TZOFFSETFROM:+0200
        TZOFFSETTO:+0100
        DTSTART:19701025T030000
        RRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=-1SU
        END:STANDARD
        END:VTIMEZONE
        BEGIN:VEVENT
        DTSTAMP:20251217T121045Z
        CLASS:PUBLIC
        CREATED:20251217T121045Z
        DTEND;TZID=Europe/Paris:20251215T100000
        DTSTART;TZID=Europe/Paris:20251215T094500
        LAST-MODIFIED:20251217T121045Z
        PRIORITY:0
        RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR
        SEQUENCE:0
        SUMMARY:Daily
        TRANSP:OPAQUE
        UID:20c37ba2-34a4-47ea-8461-9876914904c6
        END:VEVENT
        END:VCALENDAR
      ICALENDAR
    end

    it "returns all occurrences" do
      from =  Time.zone.parse("2025-12-18 00:00")
      to =    Time.zone.parse("2025-12-22 23:59")
      expected_recurrences = [

        Recurrence::Occurrence.new(
          starts_at: Time.zone.parse("2025-12-18 09:45 +0100"),
          ends_at: Time.zone.parse("2025-12-18 10:00 +0100")
        ),

        Recurrence::Occurrence.new(
          starts_at: Time.zone.parse("2025-12-19 09:45 +0100"),
          ends_at: Time.zone.parse("2025-12-19 10:00 +0100")
        ),

        # Samedi 20, pas de daily

        # Dimanche 21, pas de daily

        Recurrence::Occurrence.new(
          starts_at: Time.zone.parse("2025-12-22 09:45 +0100"),
          ends_at: Time.zone.parse("2025-12-22 10:00 +0100")
        ),

      ]
      actual_reccurrences = described_class.call(ical_calendar: every_day, from:, to:)
      expect(actual_reccurrences).to match(expected_recurrences)
    end
  end

  describe "daily event with exceptions" do
    let(:every_day_with_exceptions) do
      <<~ICALENDAR
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Open-Xchange//8.43.61//EN
        BEGIN:VTIMEZONE
        TZID:Europe/Paris
        LAST-MODIFIED:20250410T142247Z
        TZURL:https://www.tzurl.org/zoneinfo-outlook/Europe/Paris
        X-LIC-LOCATION:Europe/Paris
        BEGIN:DAYLIGHT
        TZNAME:CEST
        TZOFFSETFROM:+0100
        TZOFFSETTO:+0200
        DTSTART:19700329T020000
        RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU
        END:DAYLIGHT
        BEGIN:STANDARD
        TZNAME:CET
        TZOFFSETFROM:+0200
        TZOFFSETTO:+0100
        DTSTART:19701025T030000
        RRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=-1SU
        END:STANDARD
        END:VTIMEZONE
        BEGIN:VEVENT
        DTSTAMP:20251218T155533Z
        CLASS:PUBLIC
        CREATED:20251217T121045Z
        DTEND;TZID=Europe/Paris:20251215T100000
        DTSTART;TZID=Europe/Paris:20251215T094500
        LAST-MODIFIED:20251218T155533Z
        PRIORITY:0
        RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR
        SEQUENCE:0
        SUMMARY:Daily
        TRANSP:OPAQUE
        UID:20c37ba2-34a4-47ea-8461-9876914904c6
        END:VEVENT
        BEGIN:VEVENT
        DTSTAMP:20251218T152543Z
        CLASS:PUBLIC
        CREATED:20251218T152543Z
        DTEND;TZID=Europe/Paris:20251217T134500
        DTSTART;TZID=Europe/Paris:20251217T133000
        LAST-MODIFIED:20251218T152543Z
        PRIORITY:0
        RECURRENCE-ID;TZID=Europe/Paris:20251217T094500
        SEQUENCE:1
        SUMMARY:Daily
        TRANSP:OPAQUE
        UID:20c37ba2-34a4-47ea-8461-9876914904c6
        END:VEVENT
        BEGIN:VEVENT
        DTSTAMP:20251218T155533Z
        CLASS:PUBLIC
        CREATED:20251218T155533Z
        DTEND;TZID=Europe/Paris:20251218T100000
        DTSTART;TZID=Europe/Paris:20251218T094500
        LAST-MODIFIED:20251218T155533Z
        PRIORITY:0
        RECURRENCE-ID;TZID=Europe/Paris:20251218T094500
        SEQUENCE:0
        SUMMARY:Daily
        TRANSP:OPAQUE
        UID:20c37ba2-34a4-47ea-8461-9876914904c6
        END:VEVENT
        END:VCALENDAR
      ICALENDAR
    end

    it "returns all occurrences" do
      from =  Time.zone.parse("2025-12-18 00:00")
      to =    Time.zone.parse("2025-12-22 23:59")
      expected_recurrences = [

        Recurrence::Occurrence.new(
          starts_at: Time.zone.parse("2025-12-18 09:45 +0100"),
          ends_at: Time.zone.parse("2025-12-18 10:00 +0100")
        ),

        Recurrence::Occurrence.new(
          starts_at: Time.zone.parse("2025-12-19 09:45 +0100"),
          ends_at: Time.zone.parse("2025-12-19 10:00 +0100")
        ),

        # Samedi 20, pas de daily

        # Dimanche 21, pas de daily

        Recurrence::Occurrence.new(
          starts_at: Time.zone.parse("2025-12-22 09:45 +0100"),
          ends_at: Time.zone.parse("2025-12-22 10:00 +0100")
        ),

      ]
      actual_reccurrences = described_class.call(ical_calendar: every_day_with_exceptions, from:, to:)
      expect(actual_reccurrences).to match(expected_recurrences)
    end
  end
end
