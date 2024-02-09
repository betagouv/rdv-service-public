describe SmsJob do
  describe "error logging" do
    it "only sends error to Sentry after 3rd error" do
      allow(SmsSender).to receive(:perform_with).and_raise("erreur inattendue")

      described_class.perform_later(
        sender_name: "RdvSoli",
        phone_number: "0611223344",
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
      expect(sentry_events.last.exception.values.last.type).to eq("RuntimeError")
      expect(sentry_events.last.exception.values.last.value).to eq("erreur inattendue (RuntimeError)")
    end
  end
end
