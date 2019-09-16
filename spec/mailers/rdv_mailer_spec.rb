RSpec.describe RdvMailer, type: :mailer do
  let(:rdv) { create(:rdv) }
  let(:previous_start_at) { nil }

  shared_examples "mail with ICS" do
    it "contains the ics" do
      expect(mail.body.encoded).to match("UID:#{rdv.uuid}")
      expect(mail.body.encoded).to match("STATUS:CANCELLED") if rdv.cancelled?
    end
  end

  shared_examples "mail for rdv confirmation" do
    it "renders the subject" do
      expect(mail.subject).to eq("RDV confirmé le #{I18n.l(rdv.start_at, format: :human)}")
    end

    it "renders the body" do
      expect(mail.html_part.body.encoded).to match("RDV confirmé le #{I18n.l(rdv.start_at, format: :human)}")
    end
  end

  shared_examples "mail for updated rdv" do
    it "renders the subject" do
      expect(mail.subject).to eq("Modification de la date de votre RDV")
    end

    it "renders the body" do
      expect(mail.html_part.body.encoded).to match("Modification de votre RDV")
      expect(mail.html_part.body.encoded).to match("Votre rendez-vous initialement prévu le #{I18n.l(previous_start_at, format: :human)}")
      expect(mail.html_part.body.encoded).to match("a été déplacé au&nbsp;<strong>#{I18n.l(rdv.start_at, format: :human)}</strong>")
    end
  end

  shared_examples "mail for cancelled rdv" do
    it "renders the subject" do
      expect(mail.subject).to eq("ANNULÉ : RDV du #{I18n.l(rdv.start_at, format: :human)}")
    end

    it "renders the body" do
      expect(mail.html_part.body.encoded).to match("ANNULÉ : RDV du #{I18n.l(rdv.start_at, format: :human)}")
    end
  end

  describe "#send_ics_to_user" do
    let(:user) { rdv.users.first }
    let(:mail) { RdvMailer.send_ics_to_user(rdv, user, previous_start_at.to_s) }

    it "renders the headers" do
      expect(mail.to).to eq([user.email])
    end

    it_behaves_like "mail for rdv confirmation"

    it_behaves_like "mail with ICS"

    context "when rdv was updated" do
      let(:previous_start_at) { 2.days.ago }

      it_behaves_like "mail for updated rdv"

      it_behaves_like "mail with ICS"
    end

    context "when rdv was cancelled" do
      let(:rdv) { create(:rdv, cancelled_at: 1.day.ago) }

      it_behaves_like "mail for cancelled rdv"

      it_behaves_like "mail with ICS"
    end
  end

  describe "#send_ics_to_pro" do
    let(:pro) { create(:pro) }
    let(:mail) { RdvMailer.send_ics_to_pro(rdv, pro, previous_start_at.to_s) }

    it "renders the headers" do
      expect(mail.to).to eq([pro.email])
    end

    it_behaves_like "mail for rdv confirmation"

    it_behaves_like "mail with ICS"

    context "when rdv was updated" do
      let(:previous_start_at) { 2.days.ago }

      it_behaves_like "mail for updated rdv"

      it_behaves_like "mail with ICS"
    end

    context "when rdv was cancelled" do
      let(:rdv) { create(:rdv, cancelled_at: 1.day.ago) }

      it_behaves_like "mail for cancelled rdv"

      it_behaves_like "mail with ICS"
    end
  end
end
