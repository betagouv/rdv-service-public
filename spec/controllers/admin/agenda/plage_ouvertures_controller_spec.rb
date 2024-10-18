RSpec.describe Admin::Agenda::PlageOuverturesController, type: :controller do
  describe "GET index" do
    context "with a signed in agent" do
      let(:organisation) { create(:organisation) }
      let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }

      before { sign_in agent }

      it "return success" do
        start_date = Date.new(2019, 8, 12)
        end_date = Date.new(2019, 8, 19)
        get :index, params: { agent_id: agent.id, organisation_id: organisation.id, start: start_date, end: end_date, format: :json }
        expect(response).to be_successful
      end

      it "call Admin::Occurrence to assigns `plage_ouvertures_occurrences`" do
        given_agent = create(:agent, basic_role_in_organisations: [organisation], service: agent.services.first)

        first_day = Time.zone.parse("20190815 10h30")
        travel_to(first_day - 2.days)
        create(:plage_ouverture, agent: agent, first_day: first_day)
        create(:plage_ouverture, agent: given_agent, organisation: organisation, first_day: first_day)
        start_date = first_day - 3.days
        end_date = first_day + 4.days

        get :index, params: { agent_id: given_agent.id, organisation_id: organisation.id, start: start_date, end: end_date, format: :json }

        expect(assigns(:plage_ouverture_occurrences)).not_to be_nil
      end

      it "assigns current organisation" do
        start_date = Date.new(2019, 8, 12)
        end_date = Date.new(2019, 8, 19)
        get :index, params: { agent_id: agent.id, organisation_id: organisation.id, start: start_date, end: end_date, format: :json }
        expect(assigns(:organisation)).to eq(organisation)
      end

      describe "JSON response" do
        render_views

        let!(:plage_ouverture) { create(:plage_ouverture, agent: agent, first_day: Time.zone.today, organisation: organisation) }

        it "is serialized for FullCalendar" do
          start_date = Time.zone.today.monday
          end_date = start_date.end_of_week

          get :index, params: { agent_id: agent.id, organisation_id: organisation.id, start: start_date, end: end_date, format: :json }

          expected_response = [
            {
              "title" => plage_ouverture.title,
              "start" => plage_ouverture.starts_at.as_json,
              "end" => plage_ouverture.ends_at.as_json,
              "backgroundColor" => "#6fceff80",
              "textColor" => "#313131",
              "url" => "/admin/organisations/#{organisation.id}/plage_ouvertures/#{plage_ouverture.id}",
              "extendedProps" => {
                "organisationName" => organisation.name,
                "location" => "1 rue de l'adresse, Ville, 12345",
                "lieu" => plage_ouverture.lieu.name,
              },
            },
          ]
          expect(response.parsed_body).to eq(expected_response)
        end
      end
    end
  end
end
