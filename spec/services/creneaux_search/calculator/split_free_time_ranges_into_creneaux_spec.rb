RSpec.describe CreneauxSearch::Calculator::SplitFreeTimeRangesIntoCreneaux do
  subject(:creneaux) do
    described_class.new(free_time_ranges, duration_in_min:).perform(search_datetime_range)
  end

  let(:friday) { Time.zone.parse("20210430 8:00") }
  let(:search_datetime_range) do
    Time.zone.parse("20211027 0:00")..Time.zone.parse("20211028 0:00")
  end
  let(:duration_in_min) { 30 }

  before { travel_to(friday) }

  context "when free_time too short" do
    let(:free_time_ranges) { [Time.zone.parse("20211027 9:00")..Time.zone.parse("20211027 9:15")] }

    it { is_expected.to eq([]) }
  end

  context "when there is time for multiple créneaux" do
    let(:free_time_ranges) { [Time.zone.parse("20211027 9:00")..Time.zone.parse("20211027 10:15")] }

    it "returns slots that fit" do
      expect(creneaux.map(&:starts_at).map { _1.strftime("%H:%M") }).to eq(["09:00", "09:30"])
      expect(creneaux.map(&:duration_in_min)).to eq([30, 30])
    end
  end

  context "when passed an overridden duration_in_min" do
    let(:free_time_ranges) { [Time.zone.parse("20211027 9:00")..Time.zone.parse("20211027 10:15")] }
    let(:duration_in_min) { 20 }

    it "returns slots that fit" do
      expect(creneaux.map(&:starts_at).map { _1.strftime("%H:%M") }).to eq(["09:00", "09:20", "09:40"])
      expect(creneaux.map(&:duration_in_min)).to eq([20, 20, 20])
    end
  end

  context "quand la plage définit un intervalle entre chaque RDV" do
    let(:free_time_ranges) { [Time.zone.parse("2021-10-27 09:00")..Time.zone.parse("2021-10-27 12:00")] }

    before do
      plage_ouverture.update!(minutes_after_rdvs: 10)
    end

    it "returns slots that fit" do
      expect(creneaux.map(&:starts_at).map { _1.strftime("%H:%M") }).to eq(["09:00", "09:40", "10:20", "11:00"])
      expect(creneaux.map(&:duration_in_min)).to eq([30, 30, 30, 30])
    end
  end
end
