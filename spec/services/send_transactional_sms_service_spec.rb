# frozen_string_literal: true

describe SendTransactionalSmsService, type: :service do
  subject { described_class.new(transactional_sms) }

  let(:transactional_sms) do
    instance_double(
      TransactionalSms::RdvCreated,
      phone_number_formatted: "+33606060606",
      content: "Bonjour c'est rdv-sol",
      tags: ["RDV-Sol test", 10, "rdv_created"]
    )
  end

  describe "#perform" do
    context "production with SIB forced" do
      before do
        allow(Rails.env).to receive(:production?).and_return(true)
        allow(ENV).to receive(:[]).with("FORCE_SMS_PROVIDER").and_return("send_in_blue")
      end

      it "calls SIB API" do
        sib_api_mock = instance_double(SibApiV3Sdk::TransactionalSMSApi)
        allow(SibApiV3Sdk::TransactionalSMSApi).to receive(:new).and_return(sib_api_mock)
        expect(sib_api_mock).to receive(:send_transac_sms)
        subject.perform
      end
    end

    context "debug" do
      before { allow(Rails.env).to receive(:production?).and_return(false) }

      it "does not call netsize nor SIB" do
        # allow(Rails.logger).to receive(:debug).and_call_original # so that other calls to debug work
        # expect(Rails.logger).to receive(:debug).with(/following SMS would have been sent/)
        expect(SibApiV3Sdk::TransactionalSMSApi).not_to receive(:new)
        subject.perform
      end
    end
  end
end
