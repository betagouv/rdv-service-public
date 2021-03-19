describe Admin::Agents::AbsencesController, type: :controller do
  describe "GET index" do
    context "with a signed in agent" do
      let(:organisation) { create(:organisation) }
      let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
      before(:each) { sign_in agent }

      it "return success" do
        get :index, params: { agent_id: agent.id, organisation_id: organisation.id, format: :json }
        expect(response).to be_successful
      end

      describe "assigns absence_occurrence" do
        let(:given_agent) { create(:agent) }

        it "return only given agent's absences " do
          first_day = Date.new(2019, 8, 15)
          create(:absence, agent: agent, first_day: first_day)
          absence = create(:absence, agent: given_agent, organisation: organisation, first_day: first_day)

          get :index, params: { agent_id: given_agent.id, organisation_id: organisation.id, start: Date.new(2019, 8, 12), end: Date.new(2019, 8, 19), format: :json }

          expect(assigns(:absence_occurrences).first.first).to eq(absence)
        end

        it "assigns absence_occurrence" do
          first_day = Date.new(2019, 7, 17)
          recurrence = Montrose.every(:week, interval: 2, starts: first_day)
          create(:absence, agent: given_agent, organisation: organisation, recurrence: recurrence, first_day: first_day, start_time: Time.zone.parse("8h00"), end_time: Time.zone.parse("12h00"))

          get :index, params: { agent_id: given_agent.id, organisation_id: organisation.id, start: Date.new(2019, 8, 12), end: Date.new(2019, 8, 19), format: :json }

          expect_assigns_absence_first_occurrence_to_have(starts_at: Time.zone.parse("2019-08-14 8h00"), ends_at: Time.zone.parse("2019-08-14 12h00"))
        end

        it "returns start at and ends at for a one time only absence" do
          first_day = Date.new(2019, 7, 31)
          create(:absence, agent: given_agent, organisation: organisation, recurrence: nil, first_day: first_day, start_time: Time.zone.parse("8h00"), end_time: Time.zone.parse("12h00"))

          start_period = Date.new(2019, 7, 29)
          end_period = Date.new(2019, 8, 4)

          get :index, params: { agent_id: given_agent.id, organisation_id: organisation.id, start: start_period, end: end_period, format: :json }

          expect_assigns_absence_first_occurrence_to_have(starts_at: Time.zone.parse("2019-07-31 8h00"), ends_at: Time.zone.parse("2019-07-31 12h00"))
        end

        it "returns start at and ends at time for a 2 weeks recurrence absence" do
          first_day = Date.new(2019, 7, 31)
          recurrence = Montrose.every(:week, interval: 2, starts: first_day)
          create(:absence, agent: given_agent, organisation: organisation, recurrence: recurrence, first_day: first_day, start_time: Time.zone.parse("8h00"), end_time: Time.zone.parse("12h00"))

          start_period = Date.new(2019, 8, 12)
          end_period = Date.new(2019, 8, 19)

          get :index, params: { agent_id: given_agent.id, organisation_id: organisation.id, start: start_period, end: end_period, format: :json }

          expect_assigns_absence_first_occurrence_to_have(starts_at: Time.zone.parse("2019-08-14 8h00"), ends_at: Time.zone.parse("2019-08-14 12h00"))
        end

        def expect_assigns_absence_first_occurrence_to_have(period)
          expect(assigns(:absence_occurrences)).not_to be_blank
          first_occurrence = assigns(:absence_occurrences).first.second
          expect(first_occurrence.starts_at).to eq(period[:starts_at])
          expect(first_occurrence.ends_at).to eq(period[:ends_at])
        end
      end
    end
  end
end
