RSpec.describe Admin::Api::Agenda::ExternalCalendarEventsController, type: :controller do
  render_views

  it "contains the agent's external calendar events" do
    agent = create(:agent, :with_caldav_config)
    sign_in agent

    event_within_time_range = ExternalCalendarEvent.create!(
      agent:,
      url: "1234",
      starts_at: Time.zone.today.at(Tod::TimeOfDay.parse("10:30")),
      ends_at: Time.zone.today.at(Tod::TimeOfDay.parse("12:00"))
    )

    # Event out of time range, should not be in response
    ExternalCalendarEvent.create!(agent:, url: "5678", starts_at: 10.days.from_now, ends_at: 10.days.from_now + 2.hours)

    current_week = Time.zone.now.beginning_of_week.beginning_of_day..Time.zone.now.end_of_week.end_of_day
    get :index, params: { agent_id: agent.id, start: current_week.begin, end: current_week.end, format: :json }

    expected_response = [
      {
        "title" => "Indisponibilité provenant d’un agenda externe",
        "start" => event_within_time_range.starts_at.as_json,
        "end" => event_within_time_range.ends_at.as_json,
        "resourceIds" => [event_within_time_range.agent.id],
        "backgroundColor" => "rgba(52, 57, 58, 0.7)",
      },
    ]
    expect(response.parsed_body).to match_array(expected_response)
  end

  it "returns unauthorized if agent is not logged in" do
    get :index, params: { agent_id: 1, organisation_id: 1, start: Date.new(2019, 8, 12), end: Date.new(2019, 8, 19), format: :json }
    expect(response).to be_unauthorized
  end
end
