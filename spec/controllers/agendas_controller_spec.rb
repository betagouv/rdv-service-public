RSpec.describe AgendasController, type: :controller do
  describe "GET background_events" do
    let(:pro) { create(:pro) }
    let!(:plage_ouverture) { create(:plage_ouverture, :weekly_by_2, title: "Une semaine sur deux les mercredis à partir du 17/07", first_day: Date.new(2019, 7, 17), pro: pro) }
    let!(:plage_ouverture2) { create(:plage_ouverture, :weekly, title: "Tous les lundis à partir du 22/07", first_day: Date.new(2019, 7, 22), pro: pro) }
    let!(:plage_ouverture3) { create(:plage_ouverture, title: "Une seule fois le 24/07", first_day: Date.new(2019, 7, 24), pro: pro) }
    let!(:plage_ouverture4) { create(:plage_ouverture, title: "Une seule fois le 24/07", first_day: Date.new(2019, 7, 24), pro: pro, recurrence: Montrose::Recurrence.new) }

    before do
      sign_in pro
    end

    subject { get :background_events, params: { start: start_date, end: end_date } }

    before do
      subject
      @parsed_response = JSON.parse(response.body)
    end

    context "from 08/07/2019 to 14/07/2019" do
      let(:start_date) { Date.new(2019, 7, 8) }
      let(:end_date) { Date.new(2019, 7, 14) }

      it { expect(response).to have_http_status(:ok) }
      it { expect(response.body).to eq("[]") }
    end

    context "from 22/07/2019 to 28/07/2019" do
      let(:start_date) { Date.new(2019, 7, 22) }
      let(:end_date) { Date.new(2019, 7, 28) }

      it "should return 3 occurences from plage_ouverture2 3 and 4" do
        expect(@parsed_response.size).to eq(3)

        first = @parsed_response[0]
        expect(first.size).to eq(6)
        expect(first["title"]).to eq(plage_ouverture2.title)
        expect(first["start"]).to eq(plage_ouverture2.start_at.as_json)
        expect(first["end"]).to eq(plage_ouverture2.end_at.as_json)
        expect(first["backgroundColor"]).to eq("#F00")
        expect(first["rendering"]).to eq("background")
        expect(first["extendedProps"]).to eq({ location: plage_ouverture2.lieu.address }.as_json)

        second = @parsed_response[1]
        expect(second.size).to eq(6)
        expect(second["title"]).to eq(plage_ouverture3.title)
        expect(second["start"]).to eq("2019-07-24T08:00:00.000+02:00")
        expect(second["end"]).to eq("2019-07-24T12:00:00.000+02:00")
        expect(second["backgroundColor"]).to eq("#F00")
        expect(second["rendering"]).to eq("background")
        expect(second["extendedProps"]).to eq({ location: plage_ouverture3.lieu.address }.as_json)

        third = @parsed_response[2]
        expect(third.size).to eq(6)
        expect(third["title"]).to eq(plage_ouverture4.title)
        expect(third["start"]).to eq("2019-07-24T08:00:00.000+02:00")
        expect(third["end"]).to eq("2019-07-24T12:00:00.000+02:00")
        expect(third["backgroundColor"]).to eq("#F00")
        expect(third["rendering"]).to eq("background")
        expect(third["extendedProps"]).to eq({ location: plage_ouverture4.lieu.address }.as_json)
      end
    end

    context "from 29/07/2019 to 04/08/2019" do
      let(:start_date) { Date.new(2019, 7, 29) }
      let(:end_date) { Date.new(2019, 8, 4) }

      it "should return two occurences one from plage_ouverture and one from plage_ouverture2" do
        expect(@parsed_response.size).to eq(2)

        first = @parsed_response[0]
        expect(first.size).to eq(6)
        expect(first["title"]).to eq(plage_ouverture2.title)
        expect(first["start"]).to eq("2019-07-29T08:00:00.000+02:00")
        expect(first["end"]).to eq("2019-07-29T12:00:00.000+02:00")
        expect(first["backgroundColor"]).to eq("#F00")
        expect(first["rendering"]).to eq("background")
        expect(first["extendedProps"]).to eq({ location: plage_ouverture2.lieu.address }.as_json)

        second = @parsed_response[1]
        expect(second.size).to eq(6)
        expect(second["title"]).to eq(plage_ouverture.title)
        expect(second["start"]).to eq("2019-07-31T08:00:00.000+02:00")
        expect(second["end"]).to eq("2019-07-31T12:00:00.000+02:00")
        expect(second["backgroundColor"]).to eq("#F00")
        expect(second["rendering"]).to eq("background")
        expect(second["extendedProps"]).to eq({ location: plage_ouverture.lieu.address }.as_json)
      end
    end
  end
end
