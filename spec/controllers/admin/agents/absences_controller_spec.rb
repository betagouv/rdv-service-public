# frozen_string_literal: true

describe Admin::Agents::AbsencesController, type: :controller do
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
        given_agent = create(:agent, basic_role_in_organisations: [organisation], service: agent.service)

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

        let!(:absence) { create(:absence, agent: agent, first_day: Time.zone.today) }

        it "is serialized for FullCalendar" do
          start_date = Time.zone.today.monday
          end_date = start_date.end_of_week

          get :index, params: { agent_id: agent.id, organisation_id: organisation.id, start: start_date, end: end_date, format: :json }

          expected_response = [
            {
              "title" => absence.title,
              "start" => absence.starts_at.as_json,
              "end" => absence.ends_at.as_json,
              "backgroundColor" => "rgba(127, 140, 141, 0.7)",
              "url" => "/admin/organisations/#{organisation.id}/absences/#{absence.id}/edit",
            },
          ]
          expect(JSON.parse(response.body)).to eq(expected_response)
        end
      end
    end
  end
end
