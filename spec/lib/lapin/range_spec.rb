# frozen_string_literal: true

describe Lapin::Range do
  describe "#ensure_date_range_with_time" do
    it "returns range with given datetime_range" do
      friday = Time.zone.parse("20210430 8:00")
      travel_to(friday)
      date_range = Time.zone.parse("2021-12-20 11:00")..Time.zone.parse("2021-12-21 18:00")
      expected_range = Time.zone.parse("2021-12-20 11:00")..Time.zone.parse("2021-12-21 18:00")
      datetime_range = described_class.ensure_date_range_with_time(date_range)
      expect(datetime_range).to eq(expected_range)
    end

    it "returns range from beginning of day of range begin and end of day of range end wit date range" do
      friday = Time.zone.parse("20210430 8:00")
      travel_to(friday)
      date_range = Date.new(2021, 12, 20)..Date.new(2021, 12, 21)
      expected_range = Date.new(2021, 12, 20).beginning_of_day..(Date.new(2021, 12, 21).end_of_day)
      datetime_range = described_class.ensure_date_range_with_time(date_range)
      expect(datetime_range).to eq(expected_range)
    end

    it "returns range from now to end of given datetime range" do
      friday = Time.zone.parse("20210430 8:00")
      travel_to(friday)
      date_range = Time.zone.parse("2021-12-20 11:00")..Time.zone.parse("2021-12-21 18:00")
      expected_range = Time.zone.parse("2021-12-21 10:00")..Time.zone.parse("2021-12-21 18:00")
      now = Time.zone.parse("2021-12-21 10:00")
      travel_to(now)
      datetime_range = described_class.ensure_date_range_with_time(date_range)
      expect(datetime_range).to eq(expected_range)
    end
  end

  describe "#reduce_range_to_delay" do
    it "return date range when range in bookin period" do
      friday = Time.zone.parse("20210430 8:00")
      travel_to(friday)
      date_range = (friday + 60.minutes)..(friday + 7.days)
      motif = build(:motif, min_booking_delay: 30, max_booking_delay: 10_080)
      expected_range = (friday + 60.minutes)..(friday + 7.days)
      expect(described_class.reduce_range_to_delay(motif, date_range)).to eq(expected_range)
    end

    it "return date range starting at now + min booking delay and range end when range start before booking period" do
      friday = Time.zone.parse("20210430 8:00")
      travel_to(friday)
      date_range = friday..(friday + 7.days)
      motif = build(:motif, min_booking_delay: (3 * 24 * 60), max_booking_delay: (8 * 24 * 60))
      expected_range = friday + 3.days..(friday + 7.days)
      expect(described_class.reduce_range_to_delay(motif, date_range)).to eq(expected_range)
    end

    it "return date range ending at booking max delay when range finish after booking period" do
      friday = Time.zone.parse("20210430 8:00")
      travel_to(friday)
      date_range = (friday + 60.minutes)..(friday + 7.days)
      motif = build(:motif, min_booking_delay: 30, max_booking_delay: (3 * 24 * 60))
      expected_range = (friday + 60.minutes)..(friday + 3.days)
      expect(described_class.reduce_range_to_delay(motif, date_range)).to eq(expected_range)
    end
  end
end
