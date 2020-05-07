RSpec.describe Users::RdvMailer, type: :mailer do
  let(:rdv) { create(:rdv) }
  let(:previous_starts_at) { nil }

  shared_examples "mail with ICS" do
    it "contains the ics" do
      expect(mail.body.encoded).to match("UID:#{rdv.uuid}")
      expect(mail.body.encoded).to match("STATUS:CANCELLED") if rdv.cancelled?
    end
  end

  shared_examples "mail for rdv confirmation" do
    it "renders the subject" do
      expect(mail.subject).to eq("RDV confirmé le #{I18n.l(rdv.starts_at, format: :human)}")
    end

    it "renders the body" do
      expect(mail.html_part.body.encoded).to match("Votre RDV du #{I18n.l(rdv.starts_at, format: :human)} a été confirmé")
    end
  end

  shared_examples "mail for updated rdv" do
    it "renders the subject" do
      expect(mail.subject).to eq("Modification de la date de votre RDV")
    end

    it "renders the body" do
      expect(mail.html_part.body.encoded).to match("Modification de votre RDV")
      expect(mail.html_part.body.encoded).to match("Votre rendez-vous initialement prévu le #{I18n.l(previous_starts_at, format: :human)}")
      expect(mail.html_part.body.encoded).to match("a été déplacé au&nbsp;<strong>#{I18n.l(rdv.starts_at, format: :human)}</strong>")
    end
  end

  shared_examples "mail for cancelled rdv" do
    it "renders the subject" do
      expect(mail.subject).to eq("ANNULÉ : RDV du #{I18n.l(rdv.starts_at, format: :human)}")
    end

    it "renders the body" do
      expect(mail.html_part.body.encoded).to match("ANNULÉ : RDV du #{I18n.l(rdv.starts_at, format: :human)}")
    end
  end

  describe "#rdv_created" do
    let(:user) { rdv.users.first }
    let(:mail) { Users::RdvMailer.rdv_created(rdv, user) }

    it "renders the headers" do
      expect(mail.to).to eq([user.email])
    end

    it_behaves_like "mail for rdv confirmation"

    it_behaves_like "mail with ICS"
  end
end
