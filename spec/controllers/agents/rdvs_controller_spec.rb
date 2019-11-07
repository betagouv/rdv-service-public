RSpec.describe Agents::RdvsController, type: :controller do
  render_views

  let(:agent) { create(:agent) }
  let(:organisation_id) { agent.organisation_ids.first }
  let!(:rdv) { create(:rdv, agent_ids: [agent.id], organisation_id: organisation_id) }

  before do
    sign_in agent
  end

  describe "GET index" do
    let!(:rdv1) { create(:rdv, agents: [agent], starts_at: Time.zone.parse("21/07/2019 08:00")) }
    let!(:rdv2) { create(:rdv, agents: [agent], starts_at: Time.zone.parse("21/07/2019 09:00")) }

    subject { get(:index, params: { organisation_id: organisation_id, start: start_time, end: end_time }, as: :json) }

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
        expect(first.size).to eq(6)
        expect(first["title"]).to eq(rdv1.name)
        expect(first["start"]).to eq(rdv1.starts_at.as_json)
        expect(first["end"]).to eq(rdv1.ends_at.as_json)
        expect(first["backgroundColor"]).to eq(rdv1.motif.color)
        expect(first["url"]).to eq(organisation_rdv_path(rdv1.organisation, rdv1))
        expect(first["extendedProps"]).to eq({ status: rdv1.status, past: rdv1.past? }.as_json)

        second = @parsed_response[1]
        expect(second.size).to eq(6)
        expect(second["title"]).to eq(rdv2.name)
        expect(second["start"]).to eq(rdv2.starts_at.as_json)
        expect(second["end"]).to eq(rdv2.ends_at.as_json)
        expect(second["backgroundColor"]).to eq(rdv2.motif.color)
        expect(second["url"]).to eq(organisation_rdv_path(rdv2.organisation, rdv2))
        expect(first["extendedProps"]).to eq({ status: rdv1.status, past: rdv1.past? }.as_json)
      end
    end
  end

  describe "GET #edit" do
    it "returns a success response" do
      get :edit, params: { organisation_id: organisation_id, id: rdv.to_param }
      expect(response).to be_successful
    end
  end

  describe "PUT #update" do
    subject do
      put :update, params: { organisation_id: organisation_id, id: rdv.to_param, rdv: new_attributes }
      rdv.reload
    end

    context "with valid params" do
      let(:new_attributes) do
        {
          name: "Le nouveau nom",
        }
      end

      it "updates the requested rdv" do
        expect { subject }.to change(rdv, :name).to("Le nouveau nom")
      end

      it "redirects to the agenda" do
        subject
        expect(response).to redirect_to(rdv.agenda_path)
      end
    end

    context "with invalid params" do
      let(:new_attributes) do
        {
          duration_in_min: nil,
        }
      end

      it "returns a success response (i.e. to display the 'edit' template)" do
        subject
        expect(response).to be_successful
      end

      it "does not change rdv name" do
        expect { subject }.not_to change(rdv, :duration_in_min)
      end
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      get :show, params: { organisation_id: organisation_id, id: rdv.id }
      expect(response).to be_successful
    end
  end

  describe "POST #status" do
    subject do
      post :status, params: { organisation_id: organisation_id, id: rdv.id, rdv: { status: "waiting" }, format: "js" }
      rdv.reload
    end

    it "returns a success response" do
      subject
      expect(response).to be_successful
    end

    it "changes status" do
      expect { subject }.to change(rdv, :status).from("to_be").to("waiting")
    end
  end

  describe "DELETE destroy" do
    let(:agent) { create(:agent) }
    let(:rdv) { create(:rdv) }

    before do
      sign_in agent
    end

    it "cancel rdv" do
      expect do
        delete :destroy, params: { organisation_id: organisation_id, id: rdv.id }
        rdv.reload
      end.to change(rdv, :cancelled?).from(false).to(true)
    end
  end
end
