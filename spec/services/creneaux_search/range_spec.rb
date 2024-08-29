RSpec.describe CreneauxSearch::Range do
  describe "#ensure_date_range_with_time" do
    subject { described_class.ensure_date_range_with_time(date_range) }

    let!(:date_range) { lower_bound..higher_bound }
    let!(:now) { Time.zone.parse("2021-12-10 10:00") }

    before { travel_to(now) }

    context "when given datetime bounds" do
      let!(:lower_bound) { Time.zone.parse("2021-12-20 11:00") }
      let!(:higher_bound) { Time.zone.parse("2021-12-21 18:00") }

      it "returns range with same datetime bounds" do
        expect(subject).to eq(date_range)
      end
    end

    context "when given time bounds" do
      let!(:lower_bound) { Time.zone.parse("2021-12-20 11:00") }
      let!(:higher_bound) { Time.zone.parse("2021-12-21 18:00") }

      it "returns range with same time bounds" do
        expect(subject).to eq(date_range)
      end
    end

    context "when given date bounds" do
      let!(:lower_bound) { Date.new(2021, 12, 20) }
      let!(:higher_bound) { Date.new(2021, 12, 23) }

      it "returns bounds rounded to beginning and end of day" do
        expected_range = (lower_bound.beginning_of_day)..(higher_bound.end_of_day)
        expect(subject).to eq(expected_range)
      end
    end
  end

  describe "#reduce_range_to_delay" do
    it "return date range when range in bookin period" do
      friday = Time.zone.parse("20210430 8:00")
      travel_to(friday)
      date_range = (friday + 60.minutes)..(friday + 7.days)
      motif = build(:motif, min_public_booking_delay: 30 * 60, max_public_booking_delay: 8 * 24 * 60 * 60)
      expected_range = (friday + 60.minutes)..(friday + 7.days)
      expect(described_class.reduce_range_to_delay(motif, date_range)).to eq(expected_range)
    end

    it "return date range starting at now + min booking delay and range end when range start before booking period" do
      friday = Time.zone.parse("20210430 8:00")
      travel_to(friday)
      date_range = friday..(friday + 7.days)
      motif = build(:motif, min_public_booking_delay: (3 * 24 * 60 * 60), max_public_booking_delay: (8 * 24 * 60 * 60))
      expected_range = friday + 3.days..(friday + 7.days)
      expect(described_class.reduce_range_to_delay(motif, date_range)).to eq(expected_range)
    end

    it "return date range ending at booking max delay when range finish after booking period" do
      friday = Time.zone.parse("20210430 8:00")
      travel_to(friday)
      date_range = (friday + 60.minutes)..(friday + 7.days)
      motif = build(:motif, min_public_booking_delay: 30 * 60, max_public_booking_delay: (3 * 24 * 60 * 60))
      expected_range = (friday + 60.minutes)..(friday + 3.days)
      expect(described_class.reduce_range_to_delay(motif, date_range)).to eq(expected_range)
    end

    it "return empty range when min booking after end of range" do
      friday = Time.zone.parse("20210430 8:00")
      travel_to(friday)
      date_range = friday..(friday + 7.days)
      motif = build(:motif, min_public_booking_delay: (8 * 24 * 60 * 60), max_public_booking_delay: (9 * 24 * 60 * 60))
      expect(described_class.reduce_range_to_delay(motif, date_range)).to be_nil
    end

    it "return empty range when ..." do
      now = Time.zone.parse("20220331 10:30")
      travel_to(now)
      friday = Date.new(2022, 4, 8)
      date_range = friday..(friday + 6.days)
      motif = build(:motif, min_public_booking_delay: (1 * 24 * 60 * 60), max_public_booking_delay: (7 * 24 * 60 * 60))
      expect(described_class.reduce_range_to_delay(motif, date_range)).to be_nil
    end
  end
end
