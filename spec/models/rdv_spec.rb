describe Rdv, type: :model do
  describe '#to_ical' do
    let(:rdv) { build(:rdv) }

    subject { rdv.to_ical }

    it { is_expected.to include("SUMMARY:Rdv Michel Lapin") }
    it { is_expected.to include("DTSTART:20190704T150000") }
    it { is_expected.to include("DTEND:20190704T154500") }
    it { is_expected.to include("SEQUENCE:1") }
  end
end
