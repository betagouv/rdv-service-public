describe PlageOuverture::Ics, type: :model do
  let(:plage_ouverture) { create(:plage_ouverture, first_day: Date.new(2019, 7, 22)) }
  let(:ics) { PlageOuverture::Ics.new(plage_ouverture: plage_ouverture) }

  describe "#to_ical" do
    subject { ics.to_ical }

    it do
      is_expected.to include("SUMMARY:RDV Solidarités #{plage_ouverture.title}")
      is_expected.to match("DTSTART;TZID=Europe/Paris:20190722T080000")
      is_expected.to include("DTEND;TZID=Europe/Paris:20190722T120000")
      is_expected.to include("LOCATION:#{plage_ouverture.lieu.address}")
      is_expected.to include("ATTENDEE:mailto:#{plage_ouverture.agent.email}")
      is_expected.to include("CLASS:PUBLIC")
      is_expected.to include("METHOD:REQUEST")
    end
  end

  describe "#rrule" do
    let(:plage_ouverture) { create(:plage_ouverture, recurrence: recurrence) }

    subject { ics.rrule }

    context "every week" do
      let(:recurrence) { Montrose.every(:week, on: ["monday"]) }

      it { is_expected.to eq("FREQ=WEEKLY;BYDAY=MO;") }

      context "on monday and wednesday" do
        let(:recurrence) { Montrose.every(:week, on: %w[monday tuesday wednesday thursday friday saturday]) }

        it { is_expected.to eq("FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA;") }
      end

      context "until 22/10/2019" do
        let(:recurrence) { Montrose.every(:week, until: Time.zone.local(2019, 10, 22)) }

        it { is_expected.to eq("FREQ=WEEKLY;UNTIL=20191022T000000;") }
      end
    end

    context "every 2 weeks" do
      let(:recurrence) { Montrose.every(:week, interval: 2) }

      it { is_expected.to eq("FREQ=WEEKLY;INTERVAL=2;") }
    end

    context "every month" do
      let(:recurrence) { Montrose.every(:month) }

      it { is_expected.to eq("FREQ=MONTHLY;") }

      context "the 2nd wednesday of the month" do
        let(:recurrence) { Montrose.every(:month, day: { 3 => [2] }) }

        it { is_expected.to eq("FREQ=MONTHLY;BYDAY=2WE;") }
      end
    end
  end

  describe "#by_week_day" do
    subject { ics.send(:by_week_day, on) }

    context "repeat every friday of the week" do
      let(:on) { "friday" }

      it { is_expected.to eq("FR") }
    end

    context "repeat every monday, wednesday, friday of the week" do
      let(:on) { ["monday", "wednesday", "friday"] }

      it { is_expected.to eq("MO,WE,FR") }
    end
  end

  describe "#by_month_day" do
    subject { ics.send(:by_month_day, day) }

    context "the 2nd wednesday of the month" do
      let(:day) { { 3 => [2] } }

      it { is_expected.to eq("2WE") }
    end

    context "the 1st monday of the month" do
      let(:day) { { 1 => [1] } }

      it { is_expected.to eq("1MO") }
    end
  end
end
