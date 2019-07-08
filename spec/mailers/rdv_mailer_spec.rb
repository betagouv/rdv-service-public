RSpec.describe RdvMailer, type: :mailer do
  describe "#send_ics_to_user" do
    let(:mail) { RdvMailer.send_ics_to_user(rdv) }
    let(:rdv) { create(:rdv) }

    it "renders the headers" do
      expect(mail.to).to eq([rdv.user.email])
    end

    context "when rdv was created" do
      it "renders the body" do
        expect(mail.html_part.body.encoded).to match("RDV confirmé le #{I18n.l(rdv.start_at, format: :human)}")
      end

      it "it contains the ics" do
        expect(mail.body.encoded).to match("UID:#{rdv.uuid}")
      end
    end

    context "when rdv was updated" do
      let(:previous_start_at) { 2.days.ago }
      let(:mail) { RdvMailer.send_ics_to_user(rdv, previous_start_at.to_s) }

      it "renders the body" do
        expect(mail.html_part.body.encoded).to match("Modification de votre RDV du #{I18n.l(rdv.start_at, format: :human)}")
        expect(mail.html_part.body.encoded).to match("Votre rendez-vous initialement prévu le #{I18n.l(previous_start_at, format: :human)}")
      end

      it "contains the ics" do
        expect(mail.body.encoded).to match("UID:#{rdv.uuid}")
      end
    end

    context "when rdv was cancelled" do
      let(:rdv) { create(:rdv, cancelled_at: 1.day.ago) }
      let(:mail) { RdvMailer.send_ics_to_user(rdv) }

      it "renders the body" do
        expect(mail.html_part.body.encoded).to match("ANNULÉ : RDV du #{I18n.l(rdv.start_at, format: :human)}")
      end

      it "contains the ics" do
        expect(mail.body.encoded).to match("UID:#{rdv.uuid}")
        expect(mail.body.encoded).to match("STATUS:CANCELLED")
      end
    end
  end
end
