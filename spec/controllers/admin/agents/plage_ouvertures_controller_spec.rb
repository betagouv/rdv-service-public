describe Admin::Agents::PlageOuverturesController, type: :controller do
  describe "GET index" do
    context "with a signed in agent" do
      let(:organisation) { create(:organisation) }
      let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
      before(:each) { sign_in agent }

      it "return success" do
        start_date = Date.new(2019, 8, 12)
        end_date = Date.new(2019, 8, 19)
        get :index, params: { agent_id: agent.id, organisation_id: organisation.id, start: start_date, end: end_date, format: :json }
        expect(response).to be_successful
      end

      it "call Admin::Occurrence to assigns `plage_ouvertures_occurrences`" do
        given_agent = create(:agent, basic_role_in_organisations: [organisation], service: agent.service)

        first_day = Date.new(2019, 8, 15)
        travel_to(first_day - 2.days)
        create(:plage_ouverture, agent: agent, first_day: first_day)
        plage_ouverture = create(:plage_ouverture, agent: given_agent, organisation: organisation, first_day: first_day)
        start_date = Date.new(2019, 8, 12)
        end_date = Date.new(2019, 8, 19)
        period = start_date..end_date

        expect(Admin::Occurrence).to receive(:extract_from).with([plage_ouverture], period).and_return([[plage_ouverture, Recurrence::Occurrence.new(starts_at: start_date, ends_at: end_date)]])

        get :index, params: { agent_id: given_agent.id, organisation_id: organisation.id, start: start_date, end: end_date, format: :json }

        expect(assigns(:plage_ouverture_occurrences)).not_to be_nil
        travel_back
      end

      it "assigns current organisation" do
        start_date = Date.new(2019, 8, 12)
        end_date = Date.new(2019, 8, 19)
        get :index, params: { agent_id: agent.id, organisation_id: organisation.id, start: start_date, end: end_date, format: :json }
        expect(assigns(:organisation)).to eq(organisation)
      end
    end
  end
end
