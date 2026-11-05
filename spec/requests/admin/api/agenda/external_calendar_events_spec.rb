RSpec.describe "Admin::Api::Agenda::ExternalCalendarEventsController" do
  let(:agent) { create(:agent, :with_caldav_config) }

  before do
    travel_to(Time.zone.parse("2026-11-04 09:00"))
    sign_in agent
  end

  describe "GET /admin/api/agenda/external_calendar_events" do
    let(:week_params) { { agent_id: agent.id, start: "2026-11-02T00:00:00+01:00", end: "2026-11-09T00:00:00+01:00" } }

    context "quand l'événement dure toute la journée" do
      it "le renvoie comme un événement all day, avec des dates sans heure" do
        ExternalCalendarEvent.create!(
          agent:,
          url: "toute-la-journee",
          starts_at: Time.zone.parse("2026-11-04 00:00"),
          ends_at: Time.zone.parse("2026-11-05 00:00")
        )

        get admin_api_agenda_external_calendar_events_path, params: week_params

        expect(response.parsed_body).to contain_exactly(
          hash_including("allDay" => true, "start" => "2026-11-04", "end" => "2026-11-05")
        )
      end
    end

    context "quand l'événement récurrent dure toute la journée" do
      it "renvoie chaque occurrence comme un événement all day, même si le serveur est en UTC" do
        ExternalCalendarEvent.create!(
          agent:,
          url: "recurrent-toute-la-journee",
          starts_at: Time.zone.parse("2026-11-04 00:00"),
          ends_at: Time.zone.parse("2026-11-05 00:00"),
          raw_ical: <<~ICALENDAR
            BEGIN:VCALENDAR
            VERSION:2.0
            BEGIN:VEVENT
            DTSTAMP:20261102T090000Z
            DTSTART;VALUE=DATE:20261104
            DTEND;VALUE=DATE:20261105
            RRULE:FREQ=DAILY;COUNT=2
            UID:5b3c1a8e-3f4e-4d0c-9a8f-2d6f0c1b7e42
            END:VEVENT
            END:VCALENDAR
          ICALENDAR
        )

        ClimateControl.modify(TZ: "UTC") do
          get admin_api_agenda_external_calendar_events_path, params: week_params
        end

        expect(response.parsed_body).to contain_exactly(
          hash_including("allDay" => true, "start" => "2026-11-04", "end" => "2026-11-05"),
          hash_including("allDay" => true, "start" => "2026-11-05", "end" => "2026-11-06")
        )
      end
    end

    context "quand l'événement a des horaires" do
      it "le renvoie avec ses horaires" do
        event = ExternalCalendarEvent.create!(
          agent:,
          url: "avec-horaires",
          starts_at: Time.zone.parse("2026-11-04 10:30"),
          ends_at: Time.zone.parse("2026-11-04 12:00")
        )

        get admin_api_agenda_external_calendar_events_path, params: week_params

        expect(response.parsed_body).to contain_exactly(
          hash_including("allDay" => false, "start" => event.starts_at.as_json, "end" => event.ends_at.as_json)
        )
      end
    end
  end
end
