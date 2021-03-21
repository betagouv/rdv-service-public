describe Admin::Agents::AbsencesController, type: :controller do
  describe "GET index" do
    context "with a signed in agent" do
      let(:organisation) { create(:organisation) }
      let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
      before(:each) { sign_in agent }

      it "return success" do
        given_agent = create(:agent)
        get :index, params: { agent_id: given_agent.id, organisation_id: organisation.id, start: Date.new(2019, 8, 12), end: Date.new(2019, 8, 19), format: :json }
        expect(response).to be_successful
      end

      it "call Admin::Occurrence to assigns `absence_occurrences`" do
        given_agent = create(:agent)

        first_day = Date.new(2019, 8, 15)
        create(:absence, agent: agent, first_day: first_day)
        absence = create(:absence, agent: given_agent, organisation: organisation, first_day: first_day)
        start_date = Date.new(2019, 8, 12)
        end_date = Date.new(2019, 8, 19)
        period = start_date..end_date

        expect(Admin::Occurrence).to receive(:extract_from).with([absence], period).and_return([[absence, Recurrence::Occurrence.new(starts_at: start_date, ends_at: end_date)]])

        get :index, params: { agent_id: given_agent.id, organisation_id: organisation.id, start: start_date, end: end_date, format: :json }

        expect(assigns(:absence_occurrences)).not_to be_nil
      end
    end
  end
end
