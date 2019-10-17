RSpec.describe Agents::RdvsController, type: :controller do
  describe "DELETE destroy" do
    let(:agent) { create(:agent) }
    let(:rdv) { create(:rdv) }

    before do
      sign_in agent
    end

    it "cancel rdv" do
      delete :destroy, params: { id: rdv.id }
      expect(rdv.reload.cancelled?).to be true
    end
  end

  describe "GET index" do
    render_views

    let(:agent) { create(:agent) }
    let!(:rdv1) { create(:rdv, agents: [agent], starts_at: Time.zone.parse("21/07/2019 08:00")) }
    let!(:rdv2) { create(:rdv, agents: [agent], starts_at: Time.zone.parse("21/07/2019 09:00")) }

    before do
      sign_in agent
    end

    subject { get(:index, params: { start: start_time, end: end_time }, as: :json) }

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
        expect(first["url"]).to eq(rdv_path(rdv1))
        expect(first["extendedProps"]).to eq({ status: rdv1.status, past: rdv1.past? }.as_json)

        second = @parsed_response[1]
        expect(second.size).to eq(6)
        expect(second["title"]).to eq(rdv2.name)
        expect(second["start"]).to eq(rdv2.starts_at.as_json)
        expect(second["end"]).to eq(rdv2.ends_at.as_json)
        expect(second["backgroundColor"]).to eq(rdv2.motif.color)
        expect(second["url"]).to eq(rdv_path(rdv2))
        expect(first["extendedProps"]).to eq({ status: rdv1.status, past: rdv1.past? }.as_json)
      end
    end
  end
end
