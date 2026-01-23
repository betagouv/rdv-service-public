RSpec.describe Ical::Scrubber do
  it "deletes SUMMARY, ATTENDEES and ORGANIZER (since they can contain sensitive data)" do
    raw_ical = <<~ICAL
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
      DTSTAMP:20260123T084137Z
      ATTENDEE;CN=francois;PARTSTAT=NEEDS-ACTION;ROLE=REQ-PARTICIPANT;CUTYPE=INDI
       VIDUAL;EMAIL=francois@ferrandis.cool;X-CALENDARSERVER-DTSTAMP=20260123T084
       137Z:mailto:francois@ferrandis.cool
      ATTENDEE;CN="François, Ferrandis";PARTSTAT=ACCEPTED;ROLE=REQ-PARTICIPANT;CU
       TYPE=INDIVIDUAL;EMAIL=francois.ferrandis.ext@beta.gouv.fr;X-CALENDARSERVER
       -DTSTAMP=20260123T084052Z:mailto:francois.ferrandis.ext@beta.gouv.fr
      CLASS:PUBLIC
      CREATED:20260123T084052Z
      DESCRIPTION:description
      DTEND;TZID=Europe/Paris:20260128T110000
      DTSTART;TZID=Europe/Paris:20260128T100000
      LAST-MODIFIED:20260123T084137Z
      LOCATION:le lieu
      ORGANIZER;CN="François, Ferrandis";EMAIL=francois.ferrandis.ext@beta.gouv.f
       r:mailto:francois.ferrandis.ext@beta.gouv.fr
      PRIORITY:0
      RRULE:FREQ=WEEKLY;COUNT=2;BYDAY=WE
      SEQUENCE:1
      SUMMARY:invités
      TRANSP:OPAQUE
      UID:95aad789-4162-4fd8-bd41-2942a2b0dfac
      END:VEVENT
      END:VCALENDAR
    ICAL

    scrubbed_ical = <<~ICAL
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
      DTSTAMP:20260123T084137Z
      CLASS:PUBLIC
      CREATED:20260123T084052Z
      DTEND;TZID=Europe/Paris:20260128T110000
      DTSTART;TZID=Europe/Paris:20260128T100000
      LAST-MODIFIED:20260123T084137Z
      PRIORITY:0
      RRULE:FREQ=WEEKLY;COUNT=2;BYDAY=WE
      SEQUENCE:1
      TRANSP:OPAQUE
      UID:95aad789-4162-4fd8-bd41-2942a2b0dfac
      END:VEVENT
      END:VCALENDAR
    ICAL
    expect(described_class.new(raw_ical).scrubbed.lines).to eq(scrubbed_ical.lines)
  end
end
