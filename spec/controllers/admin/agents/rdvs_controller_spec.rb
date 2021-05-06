describe Admin::Agents::RdvsController, type: :controller do
  describe "GET index" do
    context "with a signed in agent" do
      let(:organisation) { create(:organisation) }
      let(:other_organisation) { create(:organisation) }
      let(:agent) { create(:agent, admin_role_in_organisations: [organisation, other_organisation]) }

      before { sign_in agent }

      it "return success" do
        get :index, params: { agent_id: agent.id, organisation_id: organisation.id, format: :json }
        expect(response).to be_successful
      end

      it "assigns rdvs of given agent" do
        now = Time.zone.parse("2020-12-23 15h00")
        travel_to(now)
        given_agent = create(:agent, basic_role_in_organisations: [organisation], service: agent.service)
        create(:rdv, agents: [agent])
        rdv = create(:rdv, agents: [given_agent], organisation: organisation, starts_at: now + 3.days)
        rdv_from_other_organisation = create(:rdv, agents: [given_agent], organisation: other_organisation, starts_at: now + 4.days)
        get :index, params: { agent_id: given_agent.id, organisation_id: organisation.id, format: :json }
        expect(assigns(:rdvs).sort).to eq([rdv, rdv_from_other_organisation].sort)
        travel_back
      end

      it "assigns rdvs of given agent from start to end" do
        now = Time.zone.parse("2021-01-23 10h00")
        travel_to(now)

        create(:rdv, agents: [agent], organisation: organisation, starts_at: now - 1.day)
        rdv = create(:rdv, agents: [agent], organisation: organisation, starts_at: now + 2.days)
        create(:rdv, agents: [agent], organisation: organisation, starts_at: now + 8.days)

        get :index, params: { agent_id: agent.id, organisation_id: organisation.id, start: now, end: now + 7.days, format: :json }
        expect(assigns(:rdvs)).to eq([rdv])
        travel_back
      end

      it "assigns current organisation" do
        get :index, params: { agent_id: agent.id, organisation_id: organisation.id, format: :json }
        expect(assigns(:organisation)).to eq(organisation)
      end
    end
  end
end
