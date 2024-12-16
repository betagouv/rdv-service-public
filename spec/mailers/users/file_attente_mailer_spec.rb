RSpec.describe Users::FileAttenteMailer, type: :mailer do
  describe "#new_creneau_available" do
    let(:rdv) { create(:rdv) }
    let(:user) { rdv.users.first }
    let(:mail) { described_class.with(rdv:, user:).new_creneau_available }

    specify do
      expect(mail[:from].to_s).to match(/"RDV Solidarités" <rdv\+[a-z0-9\-]+@reply\.rdv-solidarites-test\.localhost>/)
      expect(mail.to).to eq([user.email])
      expect(mail.reply_to).to be_nil
      expect(mail.subject).to eq("Un créneau vient de se liberer !")
      expect(mail.body.raw_source).to match(/Des créneaux pour votre RDV/) # for some reason, mail.html_part is nil
    end
  end
end
