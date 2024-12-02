RSpec.describe Admins::SfrMail2SmsMailer, type: :mailer do
  describe "#send_sms" do
    it "sends the email correctly" do
      mail = described_class.send_sms("test@example.com/ne-pas-repondre-grc@hauts-de-seine.fr", "0611223344", "test sms")
      expect(mail).to have_attributes(
        from: ["ne-pas-repondre-grc@hauts-de-seine.fr"],
        reply_to: nil
      )
    end
  end
end
