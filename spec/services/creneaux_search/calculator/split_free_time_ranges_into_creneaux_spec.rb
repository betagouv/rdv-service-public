RSpec.describe CreneauxSearch::Calculator::SplitFreeTimeRangesIntoCreneaux do
  subject(:creneaux) do
    described_class.new(free_time_ranges, duration_in_min:, minutes_after_rdvs:).perform(search_datetime_range)
  end

  before { travel_to(today) }

  let(:today) { Date.new(2021, 4, 29) }
  let(:tomorrow) { Date.new(2021, 4, 30) }
  let(:tomorrow_am) { Time.zone.parse("2021-04-30 09:00")..Time.zone.parse("2021-04-30 12:00") }
  let(:tomorrow_pm) { Time.zone.parse("2021-04-30 14:00")..Time.zone.parse("2021-04-30 18:00") }
  let(:free_time_ranges) { [tomorrow_am, tomorrow_pm] }

  let(:search_datetime_range) { tomorrow.all_day }
  let(:duration_in_min) { 60 }
  let(:minutes_after_rdvs) { 0 }

  it "works" do
    expected = [
      ["09:00", "10:00"],
      ["10:00", "11:00"],
      ["11:00", "12:00"],
      ["14:00", "15:00"],
      ["15:00", "16:00"],
      ["16:00", "17:00"],
      ["17:00", "18:00"],
    ]
    expect(creneaux.map { [_1.starts_at.strftime("%H:%M"), _1.ends_at.strftime("%H:%M")] }).to eq(expected)
  end

  context "when free_time too short" do
    let(:duration_in_min) { 30 }
    let(:free_time_ranges) { [Time.zone.parse("2021-04-30 09:00")..Time.zone.parse("2021-04-30 09:15")] }

    it { is_expected.to eq([]) }
  end

  context "when search_datetime_range starts after free_time_ranges" do
    let(:search_datetime_range) { today.next_week.all_week }
    let(:free_time_ranges) { [tomorrow_am, tomorrow_pm] }

    it { is_expected.to eq([]) }
  end

  context "when specifying minutes_after_rdvs" do
    let(:duration_in_min) { 30 }
    let(:minutes_after_rdvs) { 10 }

    it "add an interval of x minutes after each rdv" do
      expected = [
        ["09:00", "09:30"],
        ["09:40", "10:10"],
        ["10:20", "10:50"],
        ["11:00", "11:30"],
        ["14:00", "14:30"],
        ["14:40", "15:10"],
        ["15:20", "15:50"],
        ["16:00", "16:30"],
        ["16:40", "17:10"],
        ["17:20", "17:50"],
      ]
      expect(creneaux.map { [_1.starts_at.strftime("%H:%M"), _1.ends_at.strftime("%H:%M")] }).to eq(expected)
      expect(creneaux.map(&:duration_in_min)).to eq([30, 30, 30, 30, 30, 30, 30, 30, 30, 30])
      expect(creneaux.map(&:minutes_after_rdv)).to eq([10, 10, 10, 10, 10, 10, 10, 10, 10, 10])
    end

    context "when the last creneau ends right at the end of a free time range" do
      let(:free_time_ranges) { [tomorrow_am] }
      let(:duration_in_min) { 120 }
      let(:minutes_after_rdvs) { 60 }

      it "still is offered" do
        expect(creneaux.map { [_1.starts_at.strftime("%H:%M"), _1.ends_at.strftime("%H:%M")] }).to eq([["09:00", "11:00"]])
      end
    end
  end
end
