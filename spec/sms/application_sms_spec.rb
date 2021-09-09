# frozen_string_literal: true

module ApplicationSmsTest
  class TestSms < ApplicationSms
    def test_message(content, phone_number)
      @content = content, @phone_number = phone_number
    end
  end
end

describe ApplicationSms, type: :service do
  describe "#deliver_later" do
    subject { ApplicationSmsTest::TestSms.test_message("test", phone_number).deliver_later }

    context "phone_number is mobile" do
      let(:phone_number) { "0612345678" }

      it do
        expect(SmsSendingService).to receive(:perform_with)
        expect { subject }.not_to raise_error
      end
    end

    context "phone_number is landline" do
      let(:phone_number) { "0130303030" }

      it do
        expect { subject }.to raise_error(ApplicationSms::InvalidMobilePhoneNumberError)
      end
    end
  end
end
