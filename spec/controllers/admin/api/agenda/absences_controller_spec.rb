RSpec.describe Admin::Api::Agenda::AbsencesController, type: :controller do
  describe "GET index" do
    context "with a signed in agent" do
      let(:organisation) { create(:organisation) }
      let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }

      before { sign_in agent }

      it "return success" do
        given_agent = create(:agent, basic_role_in_organisations: [organisation])
        get :index, params: { agent_id: given_agent.id, organisation_id: organisation.id, start: Date.new(2019, 8, 12), end: Date.new(2019, 8, 19), format: :json }
        expect(response).to be_successful
      end

      it "assigns organisation" do
        given_agent = create(:agent, basic_role_in_organisations: [organisation])
        get :index, params: { agent_id: given_agent.id, organisation_id: organisation.id, start: Date.new(2019, 8, 12), end: Date.new(2019, 8, 19), format: :json }
        expect(assigns(:organisation)).to eq(organisation)
      end

      it "call Admin::Occurrence to assigns `absence_occurrences`" do
        given_agent = create(:agent, basic_role_in_organisations: [organisation], service: agent.services.first)

        first_day = Date.new(2019, 8, 15)
        create(:absence, agent: agent, first_day: first_day)
        create(:absence, agent: given_agent, first_day: first_day)
        start_date = Date.new(2019, 8, 12)
        end_date = Date.new(2019, 8, 19)

        get :index, params: { agent_id: given_agent.id, organisation_id: organisation.id, start: start_date, end: end_date, format: :json }

        expect(assigns(:absence_occurrences)).not_to be_nil
      end

      describe "JSON response" do
        render_views

        it "contains the agent's absences" do
          absence = create(:absence, agent: agent, first_day: Time.zone.today)

          start_date = Time.zone.today.monday
          end_date = start_date.end_of_week
          get :index, params: { agent_id: agent.id, organisation_id: organisation.id, start: start_date, end: end_date, format: :json }

          expected_response = [
            {
              "title" => absence.title,
              "start" => absence.starts_at.as_json,
              "end" => absence.ends_at.as_json,
              "resourceIds" => [absence.agent.id],
              "backgroundColor" => "rgba(52, 57, 58, 0.7)",
              "url" => "/admin/organisations/#{organisation.id}/planning/absences/#{absence.id}/edit",
            },
          ]
          expect(response.parsed_body).to eq(expected_response)
        end

        it "contains the agent's external calendar events" do
          agent = create(:agent, :with_caldav_config, basic_role_in_organisations: [organisation])

          external_event = ExternalCalendarEvent.create!(
            agent:,
            url: "1234",
            starts_at: Time.zone.today.at(Tod::TimeOfDay.parse("10:30")),
            ends_at: Time.zone.today.at(Tod::TimeOfDay.parse("12:00"))
          )

          start_date = Time.zone.today.monday
          end_date = start_date.end_of_week
          get :index, params: { agent_id: agent.id, organisation_id: organisation.id, start: start_date, end: end_date, format: :json }

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
      end
    end

    context "when agent is not login" do
      it "returns unauthorized" do
        get :index, params: { agent_id: 1, organisation_id: 1, start: Date.new(2019, 8, 12), end: Date.new(2019, 8, 19), format: :json }
        expect(response).to be_unauthorized
      end
    end
  end
end
