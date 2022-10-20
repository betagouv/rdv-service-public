# frozen_string_literal: true

describe SmsJob do
  subject do
    described_class.new.perform(
      sender_name: "RdvSoli",
      phone_number: phone_number,
      content: "test",
      provider: "netsize",
      api_key: "fake_key",
      receipt_params: {}
    )
  end

  context "phone_number is mobile" do
    let(:phone_number) { "0612345678" }

    specify do
      expect(SmsSender).to receive(:perform_with)
      expect { subject }.not_to raise_error
    end
  end

  context "phone_number is landline" do
    let(:phone_number) { "0130303030" }

    specify do
      expect { subject }.to raise_error(SmsJob::InvalidMobilePhoneNumberError)
    end
  end
end
