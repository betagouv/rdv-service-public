# frozen_string_literal: true

describe Admin::RdvsController, type: :controller do
  render_views

  let!(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
  let!(:user) { create(:user, first_name: "Marie", last_name: "Denis") }
  let!(:motif) { create(:motif, name: "Suivi", organisation: organisation, service: service, color: "#1010FF") }
  let!(:rdv) { create(:rdv, motif: motif, agents: [agent], users: [user], organisation: organisation) }

  before do
    sign_in agent
  end

  describe "GET index" do
    subject { get(:index, params: { organisation_id: organisation.id, agent_id: agent.id, start: start_time, end: end_time }) }

    before { subject }

    let!(:lieu) { create(:lieu, organisation: organisation, name: "MDS Orgeval") }
    let!(:rdv1) { create(:rdv, motif: motif, agents: [agent], users: [user], starts_at: Time.zone.parse("21/07/2019 08:00"), organisation: organisation, lieu: lieu) }
    let!(:rdv2) { create(:rdv, motif: motif, agents: [agent], users: [user], starts_at: Time.zone.parse("21/07/2019 07:00"), organisation: organisation, lieu: lieu) }

    context "when rdvs starts_at is in window" do
      let(:start_time) { Time.zone.parse("20/07/2019 08:00") }
      let(:end_time) { Time.zone.parse("27/07/2019 09:00") }

      it { expect(response).to be_successful }
      it { expect(assigns(:rdvs).to_a).to eq([rdv1, rdv2]) }
    end

    context "when rdvs starts_at is outside of window" do
      let(:start_time) { Time.zone.parse("10/07/2019 00:00") }
      let(:end_time) { Time.zone.parse("17/07/2019 00:00") }

      it { expect(response).to be_successful }
      it { expect(assigns(:rdvs).to_a).to eq([]) }
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

      it "where status is excused, changing other fields should not reset cancelled_at" do
        today = rdv.starts_at - 3.days
        rdv.update(cancelled_at: today, status: "excused")
        put :update, params: { organisation_id: organisation.id, id: rdv.to_param, rdv: { context: "change the context" } }
        expect(rdv.reload.cancelled_at).to eq(today)
        expect(rdv.reload.status).to eq("excused")
      end

      it "where status is excused, changing status should reset cancelled_at" do
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
      end.to change(Rdv, :count).by(-1)
    end
  end
end
