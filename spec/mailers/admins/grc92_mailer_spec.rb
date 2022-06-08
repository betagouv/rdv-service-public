# frozen_string_literal: true

RSpec.describe Admins::Grc92Mailer do
  let(:mail) { described_class.send_sms("test@example.com", "0611223344", "test sms") }

  describe "#send_sms" do
    it "sends the email correctly" do
      expect(mail).to have_attributes(
        from: ["ne-pas-repondre-grc@hauts-de-seine.fr"],
        reply_to: nil
      )
    end
  end
end
