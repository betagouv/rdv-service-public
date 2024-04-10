RSpec.describe Admin::Agenda::RdvsController, type: :controller do
  describe "GET index" do
    # Semaine du lundi 8 avril 2024 au vendredi 12 avril 2024.
    # On note que FullCalendar utilise des dates naïves (sans timezone).
    let(:fullcalendar_time_range_params) do
      {
        start: "2024-04-08T00:00:00",
        end: "2024-04-13T00:00:00", # FullCalendar utilise cette valeur pour indiquer "jusqu'au vendredi 12 inclus"
      }
    end
    let(:now) { Time.zone.parse("2024-04-08 15:00:00") }

    context "with a signed in agent" do
      let(:organisation) { create(:organisation) }
      let(:other_organisation) { create(:organisation) }
      let(:agent) { create(:agent, admin_role_in_organisations: [organisation, other_organisation]) }

      before { sign_in agent }

      it "return success" do
        get :index, params: fullcalendar_time_range_params.merge(agent_id: agent.id, organisation_id: organisation.id, format: :json)
        expect(response).to be_successful
      end

      it "assigns rdvs of given agent" do
        travel_to(now)
        given_agent = create(:agent, basic_role_in_organisations: [organisation], service: agent.services.first)
        create(:rdv, agents: [agent])
        rdv = create(:rdv, agents: [given_agent], organisation: organisation, starts_at: now + 3.days)
        rdv_from_other_organisation = create(:rdv, agents: [given_agent], organisation: other_organisation, starts_at: now + 4.days)
        get :index, params: fullcalendar_time_range_params.merge(agent_id: given_agent.id, organisation_id: organisation.id, format: :json)
        expect(assigns(:rdvs)).to contain_exactly(rdv, rdv_from_other_organisation)
      end

      it "assigns rdvs of given agent from start to end" do
        travel_to(now - 2.days)
        create(:rdv, agents: [agent], organisation: organisation, starts_at: now - 1.day)
        rdv = create(:rdv, agents: [agent], organisation: organisation, starts_at: now + 2.days)
        create(:rdv, agents: [agent], organisation: organisation, starts_at: now + 8.days)
        travel_to(now)

        get :index, params: fullcalendar_time_range_params.merge(agent_id: agent.id, organisation_id: organisation.id, start: now, end: now + 7.days, format: :json)
        expect(assigns(:rdvs)).to eq([rdv])
      end

      it "assigns current organisation" do
        get :index, params: fullcalendar_time_range_params.merge(agent_id: agent.id, organisation_id: organisation.id, format: :json)
        expect(assigns(:organisation)).to eq(organisation)
      end
    end
  end
end
