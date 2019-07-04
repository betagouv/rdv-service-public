describe Rdv, type: :model do
  describe '#to_ical' do
    let(:rdv) { build(:rdv) }

    subject { rdv.to_ical }

    it { is_expected.to include("SUMMARY:RDV Michel Lapin <> Vaccination") }
    it { is_expected.to include("DTSTART:20190704T150000") }
    it { is_expected.to include("DTEND:20190704T154500") }
    it { is_expected.to include("SEQUENCE:1") }
  end

  describe "#send_ics_to_participants" do
    let(:rdv) { build(:rdv) }

    it "should be called after create" do
      expect(rdv).to receive(:send_ics_to_participants)
      rdv.save!
    end

    subject { rdv.send_ics_to_participants }

    it "Send email to user" do
      expect(RdvMailer).to receive(:send_ics_to_user).with(rdv).and_return(double(deliver_later: nil))
      rdv.save!
    end
  end
end
