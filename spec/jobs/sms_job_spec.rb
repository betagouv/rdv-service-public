# frozen_string_literal: true

describe SmsJob do
  describe "phone number validation" do
    subject(:perform) do
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

  describe "error logging" do
    stub_sentry_events

    it "only sends error to Sentry after 3rd error" do
      described_class.perform_later(
        sender_name: "RdvSoli",
        phone_number: "0123456789",
        content: "test",
        provider: "netsize",
        api_key: "fake_key",
        receipt_params: {}
      )

      expect(enqueued_jobs.first["executions"]).to eq(0)

      # first execution, error is not logged
      perform_enqueued_jobs
      expect(enqueued_jobs.first["executions"]).to eq(1)
      expect(sentry_events).to be_empty

      # second execution, error is not logged
      perform_enqueued_jobs
      expect(enqueued_jobs.first["executions"]).to eq(2)
      expect(sentry_events).to be_empty

      # third execution, error is logged
      perform_enqueued_jobs
      expect(enqueued_jobs.first["executions"]).to eq(3)
      expect(sentry_events.last.exception.values.last.type).to eq("SmsJob::InvalidMobilePhoneNumberError")
    end
  end
end
