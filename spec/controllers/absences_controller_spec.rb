RSpec.describe AbsencesController, type: :controller do
  describe "GET index" do
    render_views

    let(:agent) { create(:agent) }
    let!(:absence1) { create(:absence, agent: agent, starts_at: Time.zone.parse("21/07/2019 08:00"), ends_at: Time.zone.parse("21/07/2019 10:00")) }
    let!(:absence2) { create(:absence, agent: agent, starts_at: Time.zone.parse("20/08/2019 08:00"), ends_at: Time.zone.parse("31/08/2019 22:00")) }

    before do
      sign_in agent
    end

    subject { get :index, params: { format: "json", start: start_time, end: end_time } }

    before do
      subject
      @parsed_response = JSON.parse(response.body)
    end

    context "when the absence is in window" do
      let(:start_time) { Time.zone.parse("20/07/2019 00:00") }
      let(:end_time) { Time.zone.parse("27/07/2019 00:00") }

      it { expect(response).to have_http_status(:ok) }

      it "should return absence1" do
        expect(@parsed_response.size).to eq(1)

        first = @parsed_response[0]
        expect(first.size).to eq(5)
        expect(first["title"]).to eq("Absence")
        expect(first["start"]).to eq(absence1.starts_at.as_json)
        expect(first["end"]).to eq(absence1.ends_at.as_json)
        expect(first["backgroundColor"]).to eq("#7f8c8d")
        expect(first["url"]).to eq(edit_absence_path(absence1))
      end
    end

    context "when the absence starts in window" do
      let(:start_time) { Time.zone.parse("19/08/2019 00:00") }
      let(:end_time) { Time.zone.parse("21/08/2019 00:00") }

      it { expect(response).to have_http_status(:ok) }

      it "should return absence2" do
        expect(@parsed_response.size).to eq(1)

        first = @parsed_response[0]
        expect(first.size).to eq(5)
        expect(first["title"]).to eq("Absence")
        expect(first["start"]).to eq(absence2.starts_at.as_json)
        expect(first["end"]).to eq(absence2.ends_at.as_json)
        expect(first["backgroundColor"]).to eq("#7f8c8d")
        expect(first["url"]).to eq(edit_absence_path(absence2))
      end
    end

    context "when the absence ends in window" do
      let(:start_time) { Time.zone.parse("31/08/2019 00:00") }
      let(:end_time) { Time.zone.parse("1/09/2019 00:00") }

      it { expect(response).to have_http_status(:ok) }

      it "should return absence2" do
        expect(@parsed_response.size).to eq(1)

        first = @parsed_response[0]
        expect(first.size).to eq(5)
        expect(first["title"]).to eq("Absence")
        expect(first["start"]).to eq(absence2.starts_at.as_json)
        expect(first["end"]).to eq(absence2.ends_at.as_json)
        expect(first["backgroundColor"]).to eq("#7f8c8d")
        expect(first["url"]).to eq(edit_absence_path(absence2))
      end
    end

    context "when the absence is around window" do
      let(:start_time) { Time.zone.parse("23/08/2019 00:00") }
      let(:end_time) { Time.zone.parse("27/08/2019 00:00") }

      it { expect(response).to have_http_status(:ok) }

      it "should return absence2" do
        expect(@parsed_response.size).to eq(1)

        first = @parsed_response[0]
        expect(first.size).to eq(5)
        expect(first["title"]).to eq("Absence")
        expect(first["start"]).to eq(absence2.starts_at.as_json)
        expect(first["end"]).to eq(absence2.ends_at.as_json)
        expect(first["backgroundColor"]).to eq("#7f8c8d")
        expect(first["url"]).to eq(edit_absence_path(absence2))
      end
    end
  end
end
