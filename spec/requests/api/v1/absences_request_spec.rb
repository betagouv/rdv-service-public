describe "api/v1/absences requests", type: :request do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, organisations: [organisation]) }

  describe "GET api/v1/absences" do
    subject { get api_v1_absences_path(params), headers: api_auth_headers_for_agent(agent) }
    let(:params) { {} }

    context "no existing absences" do
      it "returns empty array" do
        subject
        expect(response.status).to eq(200)
        result = JSON.parse(response.body)
        expect(result["absences"]).to eq([])
      end
    end

    context "some existing absences" do
      let!(:organisation2) { create(:organisation) }
      let!(:agent) { create(:agent, organisations: [organisation, organisation2]) }
      let!(:absence1) { create(:absence, agent: agent, organisation: organisation) }
      let!(:absence2) { create(:absence, agent: agent, organisation: organisation) }
      let!(:absence_org2) { create(:absence, agent: agent, organisation: organisation2) }
      let!(:other_absence) { create(:absence, agent: create(:agent), organisation: create(:organisation)) }

      it "returns policy scoped absences" do
        subject
        expect(response.status).to eq(200)
        result = JSON.parse(response.body)
        expect(result["absences"].count).to eq(3)
        expect(result["absences"].pluck("id")).to \
          contain_exactly(absence1.id, absence2.id, absence_org2.id)
      end

      context "filtered on organisation" do
        let(:params) { { organisation_id: organisation.id } }
        it "should not include orga2 absences" do
          subject
          expect(JSON.parse(response.body)["absences"].pluck("id")).to \
            contain_exactly(absence1.id, absence2.id)
        end
      end
    end
  end

  describe "POST api/v1/absences" do
    subject { post(api_v1_absences_path, params: params, headers: api_auth_headers_for_agent(agent)) }
    let(:valid_params) do
      {
        organisation_id: organisation.id,
        agent_id: agent.id,
        title: "Congé parental",
        first_day: "2020-11-20",
        start_time: "08:00",
        end_day: "2020-11-20",
        end_time: "18:30"
      }
    end

    context "valid params" do
      let(:params) { valid_params }
      it "should work" do
        expect { subject }.to(change { Absence.count }.by(1))
        expect(response.status).to eq(200)
        absence = Absence.first
        expect(absence.organisation).to eq(organisation)
        expect(absence.agent).to eq(agent)
        expect(absence.title).to eq("Congé parental")
        expect(absence.first_day).to eq(Date.parse("2020-11-20"))
        expect(absence.start_time).to eq(Tod::TimeOfDay.new(8, 0))
        expect(absence.end_day).to eq(Date.parse("2020-11-20"))
        expect(absence.end_time).to eq(Tod::TimeOfDay.new(18, 30))
      end
    end

    context "broken start_time format" do
      let(:params) { valid_params.merge(start_time: "08h") }
      it "returns an error" do
        expect { subject }.not_to(change { Absence.count })
        expect(response.status).to eq(422)
        expect(JSON.parse(response.body)["errors"]).to include("start_time doit être rempli(e)")
      end
    end

    context "end_time before start_time" do
      let(:params) { valid_params.merge(start_time: "18:00", end_time: "08:00") }
      it "returns an error" do
        expect { subject }.not_to(change { Absence.count })
        expect(response.status).to eq(422)
        expect(JSON.parse(response.body)["errors"]).to include("ends_time doit être après le début.")
      end
    end

    context "trying to create an absence for other agent in same orga but different service" do
      let!(:agent) { create(:agent, organisations: [organisation], service: create(:service), role: agent_role) }
      let!(:agent2) { create(:agent, organisations: [organisation], service: create(:service)) }
      let(:params) { valid_params.merge(agent_id: agent2.id) }

      context "agent has no special role" do
        let(:agent_role) { :user }
        it "returns an error" do
          expect { subject }.not_to(change { Absence.count })
          expect(response.status).to eq(403)
          expect(JSON.parse(response.body)["errors"]).to include("Vous ne pouvez pas effectuer cette action.")
        end
      end

      context "agent is admin" do
        let(:agent_role) { :admin }
        it "returns an error" do
          expect { subject }.to(change { Absence.count }.by(1))
          expect(response.status).to eq(200)
          expect(Absence.first.agent).to eq(agent2)
        end
      end
    end

    context "empty params" do
      let(:params) { {} }
      it "returns an error" do
        expect { subject }.not_to(change { Absence.count })
        expect(response.status).to eq(422)
      end
    end

    # context "invalid JSON" do
    #   it "returns an error" do
    #     post(api_v1_absences_path, body: valid_params.to_json[0..-5], headers: api_auth_headers_for_agent(agent))
    #     expect(response.status).to eq(400)
    #   end
    # end
  end
end
