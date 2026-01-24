RSpec.describe Admin::Api::Agenda::ExternalCalendarEventsController, type: :controller do
  render_views

  it "contains the agent's external calendar events" do
    agent = create(:agent, :with_caldav_config)
    sign_in agent

    external_event = ExternalCalendarEvent.create!(
      agent:,
      url: "1234",
      starts_at: Time.zone.today.at(Tod::TimeOfDay.parse("10:30")),
      ends_at: Time.zone.today.at(Tod::TimeOfDay.parse("12:00"))
    )

    start_date = Time.zone.today.monday
    end_date = start_date.end_of_week
    get :index, params: { agent_id: agent.id, start: start_date, end: end_date, format: :json }

    expected_response = [
      {
        "title" => "Indisponibilité provenant d’un agenda externe",
        "start" => external_event.starts_at.as_json,
        "end" => external_event.ends_at.as_json,
        "resourceIds" => [external_event.agent.id],
        "backgroundColor" => "rgba(52, 57, 58, 0.7)",
      },
    ]
    expect(response.parsed_body).to eq(expected_response)
  end

  it "returns unauthorized if agent is not logged in" do
    get :index, params: { agent_id: 1, organisation_id: 1, start: Date.new(2019, 8, 12), end: Date.new(2019, 8, 19), format: :json }
    expect(response).to be_unauthorized
  end
end
