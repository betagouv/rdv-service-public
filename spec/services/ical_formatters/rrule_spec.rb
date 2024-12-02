RSpec.describe IcalFormatters::Rrule do
  describe "#from_recurrence" do
    subject { described_class.from_recurrence(recurrence) }

    let(:first_day) { Date.new(2019, 7, 22) }

    before { travel_to(Time.zone.parse("20190628 17h43")) }

    context "every week" do
      context "on monday" do
        let(:recurrence) { Montrose.every(:week, on: ["monday"], starts: first_day) }

        it { is_expected.to eq("FREQ=WEEKLY;BYDAY=MO;") }
      end

      context "on monday and wednesday" do
        let(:recurrence) { Montrose.every(:week, on: %w[monday tuesday wednesday thursday friday saturday], starts: first_day) }

        it { is_expected.to eq("FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA;") }
      end

      context "until 22/10/2019" do
        let(:recurrence) { Montrose.every(:week, until: Time.zone.local(2019, 10, 22), starts: first_day) }

        it { is_expected.to eq("FREQ=WEEKLY;UNTIL=20191022T000000;") }
      end
    end

    context "every 2 weeks" do
      let(:recurrence) { Montrose.every(:week, interval: 2, starts: first_day) }

      it { is_expected.to eq("FREQ=WEEKLY;INTERVAL=2;") }
    end

    context "every month" do
      context "once" do
        let(:recurrence) { Montrose.every(:month, starts: first_day) }

        it { is_expected.to eq("FREQ=MONTHLY;") }
      end

      context "the 2nd wednesday of the month" do
        let(:recurrence) { Montrose.every(:month, day: { 3 => [2] }, starts: first_day) }

        it { is_expected.to eq("FREQ=MONTHLY;BYDAY=2WE;") }
      end
    end
  end
end
