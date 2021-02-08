describe SendTransactionalSmsService, type: :service do
  subject { SendTransactionalSmsService.new(transactional_sms) }
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
      before { allow(Rails.env).to receive(:production?).and_return(true) }
      before { allow(ENV).to receive(:[]).with("FORCE_SMS_PROVIDER").and_return("send_in_blue") }
      it "calls SIB API" do
        sib_api_mock = instance_double(SibApiV3Sdk::TransactionalSMSApi)
        expect(SibApiV3Sdk::TransactionalSMSApi).to receive(:new).and_return(sib_api_mock)
        expect(sib_api_mock).to receive(:send_transac_sms)
        subject.perform
      end
    end

    context "production without SIB forced" do
      before { allow(Rails.env).to receive(:production?).and_return(true) }
      before { expect(subject).to receive(:env_force_sms_provider).and_return(nil) }
      it "calls netsize", skip: true do
        subject.perform
      end
    end

    context "debug" do
      before { allow(Rails.env).to receive(:production?).and_return(false) }
      it "should not call netsize nor SIB" do
        # allow(Rails.logger).to receive(:debug).and_call_original # so that other calls to debug work
        # expect(Rails.logger).to receive(:debug).with(/following SMS would have been sent/)
        expect(SibApiV3Sdk::TransactionalSMSApi).not_to receive(:new)
        subject.perform
      end
    end
  end
end
