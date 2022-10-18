# frozen_string_literal: true

describe "api/v1/absences requests", type: :request do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }

  describe "GET api/v1/absences" do
    subject { get api_v1_absences_path(params), headers: api_auth_headers_for_agent(agent) }

    let(:params) { {} }

    context "no existing absences" do
      it "returns empty array" do
        subject
        expect(response.status).to eq(200)
        expect(parsed_response_body["absences"]).to eq([])
      end
    end

    context "some existing absences" do
      let!(:organisation2) { create(:organisation) }
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation, organisation2]) }
      let!(:absence1) { create(:absence, agent: agent, organisation: organisation) }
      let!(:absence2) { create(:absence, agent: agent, organisation: organisation) }
      let!(:absence_org2) { create(:absence, agent: agent, organisation: organisation2) }
      let!(:other_organisation) { create(:organisation) }
      let!(:other_agent) { create(:agent, basic_role_in_organisations: [other_organisation]) }
      let!(:other_absence) { create(:absence, agent: other_agent, organisation: other_organisation) }

      it "returns policy scoped absences" do
        subject
        expect(response.status).to eq(200)
        expect(parsed_response_body["absences"].count).to eq(3)
        expect(parsed_response_body["absences"].pluck("id")).to \
          contain_exactly(absence1.id, absence2.id, absence_org2.id)
      end

      context "filtered on organisation" do
        let(:params) { { organisation_id: organisation.id } }

        it "does not include orga2 absences" do
          subject
          expect(parsed_response_body["absences"].pluck("id")).to \
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
        end_time: "18:30",
      }
    end

    context "valid params" do
      let(:params) { valid_params }

      it "works" do
        expect { subject }.to(change(Absence, :count).by(1))
        expect(response.status).to eq(200)
        absence = Absence.by_starts_at.first
        expect(absence.organisation).to eq(organisation)
        expect(absence.agent).to eq(agent)
        expect(absence.title).to eq("Congé parental")
        expect(absence.first_day).to eq(Date.parse("2020-11-20"))
        expect(absence.start_time).to eq(Tod::TimeOfDay.new(8, 0))
        expect(absence.end_day).to eq(Date.parse("2020-11-20"))
        expect(absence.end_time).to eq(Tod::TimeOfDay.new(18, 30))
      end
    end

    context "agent specified by email" do
      context "email in known" do
        let(:params) do
          valid_params.except(:agent_id)
            .merge(agent_email: agent.email)
        end

        it "works" do
          expect { subject }.to(change(Absence, :count).by(1))
          expect(response.status).to eq(200)
          absence = Absence.by_starts_at.first
          expect(absence.agent).to eq(agent)
        end
      end

      context "email in unknown" do
        let(:params) do
          valid_params.except(:agent_id)
            .merge(agent_email: "other_email")
        end

        it "fails" do
          expect { subject }.not_to(change(Absence, :count))
          expect(response.status).to eq(404)
        end
      end
    end

    context "broken start_time format" do
      let(:params) { valid_params.merge(start_time: "08h") }

      it "returns an error" do
        expect { subject }.not_to(change(Absence, :count))
        expect(response.status).to eq(422)
        expect(parsed_response_body["error_messages"]).to include("start_time doit être rempli(e)")
      end
    end

    context "end_time before start_time" do
      let(:params) { valid_params.merge(start_time: "18:00", end_time: "08:00") }

      it "returns an error" do
        expect { subject }.not_to(change(Absence, :count))
        expect(response.status).to eq(422)
        expect(parsed_response_body["error_messages"]).to include("ends_time doit être après le début.")
      end
    end

    context "trying to create an absence for other agent in same orga but different service" do
      let!(:agent) { create(:agent, service: create(:service)) }
      let!(:agent_role) { create(:agent_role, agent: agent, level: agent_role_level, organisation: organisation) }
      let!(:agent2) { create(:agent, basic_role_in_organisations: [organisation], service: create(:service)) }
      let(:params) { valid_params.merge(agent_id: agent2.id) }

      context "agent has no special role" do
        let(:agent_role_level) { AgentRole::LEVEL_BASIC }

        it "returns an error" do
          expect { subject }.not_to(change(Absence, :count))
          expect(response.status).to eq(403)
          expect(parsed_response_body["error_messages"]).to include("Vous ne pouvez pas effectuer cette action.")
        end
      end

      context "agent is admin" do
        let(:agent_role_level) { AgentRole::LEVEL_ADMIN }

        it "returns an error" do
          expect { subject }.to(change(Absence, :count).by(1))
          expect(response.status).to eq(200)
          expect(Absence.by_starts_at.first.agent).to eq(agent2)
        end
      end
    end

    context "empty params" do
      let(:params) { {} }

      it "returns an error" do
        expect { subject }.not_to(change(Absence, :count))
        expect(response.status).to eq(422)
      end
    end
  end

  describe "SHOW api/v1/absences/:id" do
    subject { get(api_v1_absence_path(absence.id), headers: api_auth_headers_for_agent(agent)) }

    context "authorized absence" do
      let(:absence) { create(:absence, agent: agent, organisation: organisation) }

      it "works" do
        subject
        expect(response.status).to eq(200)
        result = parsed_response_body
        expect(result["absence"]["title"]).to eq(absence.title)
      end
    end

    context "unauthorized absence" do
      let(:absence) { create(:absence) }

      it "returns an error" do
        subject
        expect(response.status).to eq(404)
      end
    end
  end

  describe "PUT api/v1/absences/:id" do
    subject { put(api_v1_absence_path(absence.id), params: params, headers: api_auth_headers_for_agent(agent)) }

    let(:params) { { title: "Updated" } }

    context "authorized absence" do
      let(:absence) { create(:absence, agent: agent, organisation: organisation, title: "Initial") }

      it "works" do
        subject
        expect(response.status).to eq(200)
        expect(absence.reload.title).to eq("Updated")
      end
    end

    context "unauthorized absence" do
      let(:absence) { create(:absence, title: "Initial") }

      it "returns an error" do
        subject
        expect(response.status).to eq(404)
        expect(absence.reload.title).to eq("Initial")
      end
    end
  end

  describe "DELETE api/v1/absences/:id" do
    subject { delete(api_v1_absence_path(absence.id), headers: api_auth_headers_for_agent(agent)) }

    context "authorized absence" do
      let(:absence) { create(:absence, agent: agent, organisation: organisation) }

      it "works" do
        subject
        expect(response.status).to eq(204)
        expect { absence.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "unauthorized absence" do
      let(:absence) { create(:absence) }

      it "returns an error" do
        subject
        expect(response.status).to eq(404)
        expect(absence).not_to be_destroyed
      end
    end
  end
end
