RSpec.describe Ical::RruleExpander do
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
      expected_recurrence = [
        Time.zone.parse("2025-12-18 14:00 +0100"),
        Time.zone.parse("2025-12-18 15:00 +0100"),
      ]
      actual_recurrences = described_class.new(ponctuel).compute_occurrences_within(from..to)
      expect(actual_recurrences.sole.to_a).to match(expected_recurrence)
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
        [
          Time.zone.parse("2025-12-18 09:45 +0100"),
          Time.zone.parse("2025-12-18 10:00 +0100"),
        ],

        [
          Time.zone.parse("2025-12-19 09:45 +0100"),
          Time.zone.parse("2025-12-19 10:00 +0100"),
        ],

        # Samedi 20, pas de daily

        # Dimanche 21, pas de daily

        [
          Time.zone.parse("2025-12-22 09:45 +0100"),
          Time.zone.parse("2025-12-22 10:00 +0100"),
        ],
      ]
      actual_recurrences = described_class.new(every_day).compute_occurrences_within(from..to)
      expect(actual_recurrences.map(&:to_a)).to match(expected_recurrences)
    end
  end

  describe "weekly event with exceptions" do
    # Événement récurrent :
    # - tous les mardis à 11h
    # - commençant le mardi 13 janvier 2026
    # - décalé à 16h exceptionnellement le mardi 20 janvier 2026
    # - supprimé le 3 février
    # - fin de récurrence le 10 mars
    let(:every_week_with_exception) do
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
        DTSTAMP:20260113T143923Z
        CLASS:PUBLIC
        CREATED:20260113T132954Z
        DTEND;TZID=Europe/Paris:20260113T123000
        DTSTART;TZID=Europe/Paris:20260113T110000
        EXDATE;TZID=Europe/Paris:20260203T110000
        LAST-MODIFIED:20260113T143923Z
        PRIORITY:0
        RRULE:FREQ=WEEKLY;UNTIL=20260310T095959Z;BYDAY=TU
        SEQUENCE:2
        SUMMARY:Weekly avec la team
        TRANSP:OPAQUE
        UID:aa3e11cb-fb43-4e42-b4ed-954ea11ea3fe
        END:VEVENT
        BEGIN:VEVENT
        DTSTAMP:20260113T142328Z
        CLASS:PUBLIC
        CREATED:20260113T142328Z
        DTEND;TZID=Europe/Paris:20260120T173000
        DTSTART;TZID=Europe/Paris:20260120T160000
        LAST-MODIFIED:20260113T142328Z
        PRIORITY:0
        RECURRENCE-ID;TZID=Europe/Paris:20260120T110000
        SEQUENCE:1
        SUMMARY:Weekly avec la team
        TRANSP:OPAQUE
        UID:aa3e11cb-fb43-4e42-b4ed-954ea11ea3fe
        END:VEVENT
        END:VCALENDAR
      ICALENDAR
    end

    it "returns all occurrences including exceptions" do
      from =  Time.zone.parse("2026-01-13 00:00")
      to =    Time.zone.parse("2026-06-29 23:59")
      expected_recurrences = [
        [
          "2026-01-13 11:00",
          "2026-01-13 12:30",
        ],
        # Exception : ce weekly du mardi aura lieu à 16h au lieu de 11h
        [
          "2026-01-20 16:00",
          "2026-01-20 17:30",
        ],
        [
          "2026-01-27 11:00",
          "2026-01-27 12:30",
        ],
        # Supprimée le 3 février
        # [
        #   "2026-02-03 11:00",
        #   "2026-02-03 12:30",
        # ],
        [
          "2026-02-10 11:00",
          "2026-02-10 12:30",
        ],
        [
          "2026-02-17 11:00",
          "2026-02-17 12:30",
        ],
        [
          "2026-02-24 11:00",
          "2026-02-24 12:30",
        ],
        [
          "2026-03-03 11:00",
          "2026-03-03 12:30",
        ],
        # plus rien après le 3 mars puisque récurrence supprimée le 10 mars pour toujours
      ]
      actual_recurrences = described_class.new(every_week_with_exception).compute_occurrences_within(from..to)
      expect(actual_recurrences.map(&:to_a)).to match(expected_recurrences.map { _1.map { |str| Time.zone.parse(str) } })
    end
  end

  describe "change to a recurring event" do
    # Le payload iCal ci-dessous a été reçu lorsque j'ai déplacé une récurrence
    # d'un événement "Daily" à 11:15.
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
        DTSTAMP:20251218T162713Z
        CLASS:PUBLIC
        CREATED:20251218T160912Z
        DTEND;TZID=Europe/Paris:20251215T113000
        DTSTART;TZID=Europe/Paris:20251215T111500
        LAST-MODIFIED:20251218T162713Z
        PRIORITY:0
        RECURRENCE-ID;TZID=Europe/Paris:20251215T101500
        RELATED-TO;RELTYPE=X-CALENDARSERVER-RECURRENCE-SET:4bb41a97-1397-417d-a8a8-
         ec29643bae12
        SEQUENCE:6
        SUMMARY:Daily
        TRANSP:OPAQUE
        UID:244ba0d4-6b21-4801-9a52-83f3dc6b4e7f
        X-OX-SPLIT-FROM:20c37ba2-34a4-47ea-8461-9876914904c6
        END:VEVENT
        END:VCALENDAR
      ICALENDAR
    end

    it "returns all occurrences" do
      from =  Time.zone.parse("2025-12-15 00:00")
      to =    Time.zone.parse("2025-12-22 23:59")
      expected_recurrence = [
        Time.zone.parse("2025-12-15 11:15 +0100"),
        Time.zone.parse("2025-12-15 11:30 +0100"),
      ]
      actual_recurrences = described_class.new(every_day_with_exceptions).compute_occurrences_within(from..to)
      expect(actual_recurrences.sole.to_a).to match(expected_recurrence)
    end
  end

  describe "transparent recurring event with one opaque exception" do
    # Un événement récurrent tous les mercredis à partir du 21 janvier.
    # Il a une exception : il est OPAQUE le 28 janvier.
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
        DTSTAMP:20260126T100012Z
        CLASS:PUBLIC
        CREATED:20260126T100002Z
        DTEND;TZID=Europe/Paris:20260121T153000
        DTSTART;TZID=Europe/Paris:20260121T150000
        LAST-MODIFIED:20260126T100012Z
        PRIORITY:0
        RRULE:FREQ=WEEKLY;BYDAY=WE
        SEQUENCE:0
        SUMMARY:recur trans
        TRANSP:TRANSPARENT
        UID:aa1330f6-7925-4125-bec4-99126dec84c7
        END:VEVENT
        BEGIN:VEVENT
        DTSTAMP:20260126T100012Z
        CLASS:PUBLIC
        CREATED:20260126T100012Z
        DTEND;TZID=Europe/Paris:20260128T153000
        DTSTART;TZID=Europe/Paris:20260128T150000
        LAST-MODIFIED:20260126T100012Z
        PRIORITY:0
        RECURRENCE-ID;TZID=Europe/Paris:20260128T150000
        SEQUENCE:1
        SUMMARY:recur trans
        TRANSP:OPAQUE
        UID:aa1330f6-7925-4125-bec4-99126dec84c7
        END:VEVENT
        END:VCALENDAR
      ICALENDAR
    end

    it "returns all occurrences" do
      from =  Time.zone.parse("2026-01-01 00:00")
      to =    Time.zone.parse("2026-02-31 23:59")
      expected_recurrence = [
        # On ne liste que l'occurrence qui est OPAQUE
        Time.zone.parse("2026-01-28 15:00 +0100"),
        Time.zone.parse("2026-01-28 15:30 +0100"),
      ]
      actual_recurrences = described_class.new(every_day_with_exceptions).compute_occurrences_within(from..to)
      expect(actual_recurrences.sole.to_a).to match(expected_recurrence)
    end
  end
end
