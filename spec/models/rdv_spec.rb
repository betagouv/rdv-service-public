describe Rdv, type: :model do
  describe '#to_ical' do
    let(:rdv) { create(:rdv) }

    subject { rdv.to_ical }

    it { is_expected.to include("SUMMARY:RDV Michel Lapin <> Vaccination") }
    it { is_expected.to include("DTSTART:20190704T150000") }
    it { is_expected.to include("DTEND:20190704T154500") }
    it { is_expected.to include("SEQUENCE:0") }
    it { is_expected.to include("UID:") }

    context 'when rdv is cancelled' do
      let(:rdv) { create(:rdv, cancelled_at: Time.zone.now) }
      it { is_expected.to include("STATUS:CANCELLED") }
    end
  end

  describe "#send_ics_to_participants" do
    let(:rdv) { build(:rdv) }

    it "should be called after create" do
      expect(rdv).to receive(:send_ics_to_participants)
      rdv.save!
    end

    context "when rdv already exist" do
      let(:rdv) { create(:rdv) }

      it "should not be called" do
        expect(rdv).not_to receive(:send_ics_to_participants)
        rdv.save!
      end
    end

    it "calls RdvMailer to send email to user" do
      expect(RdvMailer).to receive(:send_ics_to_user).with(rdv).and_return(double(deliver_later: nil))
      rdv.save!
    end
  end

  describe "#update_ics_to_participants" do
    let(:rdv) { build(:rdv) }

    it "should not be called after create" do
      expect(rdv).not_to receive(:update_ics_to_participants)
      rdv.save!
    end

    context "when rdv already exist" do
      let(:rdv) { create(:rdv) }

      it "should not be called if there is no change" do
        expect(rdv).not_to receive(:update_ics_to_participants)
        rdv.save!
      end

      context "and start_at changed" do
        let!(:old_start_at) { rdv.start_at }
        before { rdv.start_at = 2.days.from_now }

        it "should be called if start_at changed" do
          expect(rdv).to receive(:update_ics_to_participants)
          rdv.save!
        end

        it "should increment sequence" do
          expect { rdv.save! }.to change { rdv.sequence }.from(0).to(1)
        end

        it "Send email to user" do
          expect(RdvMailer).to receive(:send_ics_to_user).with(rdv, old_start_at.to_s).and_return(double(deliver_later: nil))
          rdv.save!
        end
      end
    end
  end

  describe "#cancel" do
    let(:rdv) { create(:rdv) }
    let(:now) { Time.zone.now }

    subject { rdv.cancel }

    before { Timecop.freeze(now) }
    after { Timecop.return }

    it "should set cancelled_at" do
      expect { subject }.to change { rdv.cancelled_at }.from(nil).to(now)
    end

    it "should increment sequence" do
      expect { subject }.to change { rdv.sequence }.from(0).to(1)
    end

    it "Send email to user" do
      expect(RdvMailer).to receive(:send_ics_to_user).with(rdv, nil).and_return(double(deliver_later: nil))
      subject
    end
  end
end
