RSpec.describe Admin::RdvsController, type: :controller do
  render_views

  let!(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }
  let(:agent) { create(:agent, organisations: [organisation], service: service) }
  let!(:user) { create(:user, first_name: "Marie", last_name: "Denis") }
  let!(:motif) { create(:motif, name: "Suivi", organisation: organisation, service: service) }
  let!(:rdv) { create(:rdv, motif: motif, agents: [agent], users: [user], organisation: organisation) }

  before do
    sign_in agent
  end

  describe "GET index" do
    let!(:lieu) { create(:lieu, organisation: organisation, name: "MDS Orgeval") }
    let!(:rdv1) { create(:rdv, motif: motif, agents: [agent], users: [user], starts_at: Time.zone.parse("21/07/2019 08:00"), organisation: organisation, lieu: lieu) }
    let!(:rdv2) { create(:rdv, motif: motif, agents: [agent], users: [user], starts_at: Time.zone.parse("21/07/2019 07:00"), organisation: organisation, lieu: lieu) }

    subject { get(:index, params: { organisation_id: organisation.id, agent_id: agent.id, start: start_time, end: end_time }, as: :json) }

    before do
      subject
      @parsed_response = JSON.parse(response.body)
    end

    context "when rdvs starts_at is in window" do
      let(:start_time) { Time.zone.parse("20/07/2019 00:00") }
      let(:end_time) { Time.zone.parse("27/07/2019 00:00") }

      it { expect(response).to have_http_status(:ok) }

      it "should return absence1" do
        expect(@parsed_response.size).to eq(2)

        first = @parsed_response[0]
        expect(first.size).to eq(7)
        expect(first["title"]).to eq("Marie DENIS")
        expect(first["start"]).to eq(rdv1.starts_at.as_json)
        expect(first["end"]).to eq(rdv1.ends_at.as_json)
        expect(first["backgroundColor"]).to eq(rdv1.motif.color)
        expect(first["url"]).to eq(admin_organisation_rdv_path(rdv1.organisation, rdv1, agent_id: agent.id))
        expect(first["extendedProps"]).to eq({ readableStatus: Rdv.human_enum_name(:status, rdv1.status), status: rdv1.status, motif: "Suivi", past: rdv1.past?, duration: rdv.duration_in_min, lieu: "MDS Orgeval", overlappingPlagesOuvertures: false }.as_json)

        second = @parsed_response[1]
        expect(second.size).to eq(7)
        expect(second["title"]).to eq("Marie DENIS")
        expect(second["start"]).to eq(rdv2.starts_at.as_json)
        expect(second["end"]).to eq(rdv2.ends_at.as_json)
        expect(second["backgroundColor"]).to eq(rdv2.motif.color)
        expect(second["url"]).to eq(admin_organisation_rdv_path(rdv2.organisation, rdv2, agent_id: agent.id))
        expect(first["extendedProps"]).to eq({ readableStatus: Rdv.human_enum_name(:status, rdv2.status), status: rdv2.status, motif: rdv2.motif.name, past: rdv2.past?, duration: rdv.duration_in_min, lieu: "MDS Orgeval", overlappingPlagesOuvertures: false }.as_json)
      end
    end

    context "when rdvs starts_at is outside of window" do
      let(:start_time) { Time.zone.parse("10/07/2019 00:00") }
      let(:end_time) { Time.zone.parse("17/07/2019 00:00") }

      it "should return no rdvs" do
        expect(@parsed_response.size).to eq(0)
      end
    end
  end

  describe "GET #edit" do
    it "returns a success response" do
      get :edit, params: { organisation_id: organisation.id, id: rdv.to_param }
      expect(response).to be_successful
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      it "updates the requested rdv" do
        lieu = create(:lieu, organisation: organisation)
        put :update, params: { organisation_id: organisation.id, id: rdv.to_param, rdv: { lieu_id: lieu.id } }
        expect(rdv.reload.lieu).to eq(lieu)
      end

      it "updates the requested rdv status" do
        put :update, params: { organisation_id: organisation.id, id: rdv.to_param, rdv: { status: "waiting" } }
        expect(rdv.reload.status).to eq("waiting")
      end

      it "set cancelled_at to nil when change status from cancel to other" do
        rdv = create(:rdv, :excused, motif: motif, agents: [agent], users: [user], organisation: organisation)
        put :update, params: { organisation_id: organisation.id, id: rdv.to_param, rdv: { status: "waiting" } }
        expect(rdv.reload.cancelled_at).to eq(nil)
        expect(rdv.reload.status).to eq("waiting")
      end

      it "redirects to the rdv" do
        lieu = create(:lieu, organisation: organisation)
        put :update, params: { organisation_id: organisation.id, id: rdv.to_param, rdv: { lieu_id: lieu.id } }
        expect(response).to redirect_to(admin_organisation_rdv_path(organisation, rdv))
      end

      it "where status is excused, cancelled_at should not be nil" do
        today = rdv.starts_at - 3.days
        travel_to(today)
        put :update, params: { organisation_id: organisation.id, id: rdv.to_param, rdv: { status: "excused" } }
        expect(rdv.reload.cancelled_at).to eq(today)
        expect(rdv.reload.status).to eq("excused")
      end

      it "where status is excused, change other field should not reset cancelled_at" do
        tomorrow = Time.zone.parse("23/07/2019 08:00")
        today = tomorrow - 1.day
        travel_to(today)

        rdv = create(:rdv, :excused, cancelled_at: today + 3.days, starts_at: tomorrow, motif: motif, agents: [agent], users: [user], organisation: organisation)

        expect(rdv.reload.cancelled_at).to be_within(5.seconds).of(today + 3.days)
        put :update, params: { organisation_id: organisation.id, id: rdv.to_param, rdv: { context: "change some context" } }
        expect(rdv.reload.cancelled_at).to be_within(5.seconds).of(today + 3.days)
        expect(rdv.reload.status).to eq("excused")
      end

      it "where status is excused, change other field should not reset cancelled_at" do
        rdv.update(cancelled_at: 2.days.ago, status: "excused")
        put :update, params: { organisation_id: organisation.id, id: rdv.to_param, rdv: { status: "unknown" } }
        expect(rdv.reload.cancelled_at).to eq(nil)
        expect(rdv.reload.status).to eq("unknown")
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'edit' template)" do
        new_attributes = { duration_in_min: nil }
        put :update, params: { organisation_id: organisation.id, id: rdv.to_param, rdv: new_attributes }
        expect(response).to be_successful
        expect(response).to render_template(:edit)
      end

      it "does not change rdv" do
        new_attributes = { duration_in_min: nil }
        expect do
          put :update, params: { organisation_id: organisation.id, id: rdv.to_param, rdv: new_attributes }
        end.not_to change(rdv, :duration_in_min)
      end
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      get :show, params: { organisation_id: organisation.id, id: rdv.id }
      expect(response).to be_successful
    end
  end

  describe "DELETE destroy" do
    it "cancel rdv" do
      expect do
        delete :destroy, params: { organisation_id: organisation.id, id: rdv.id }
      end.to change { Rdv.count }.by(-1)
    end
  end
end
