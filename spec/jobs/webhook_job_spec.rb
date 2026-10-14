RSpec.describe WebhookJob do
  describe "#perform" do
    let(:payload) { "{}" }
    let(:webhook_endpoint) { create(:webhook_endpoint, :bypassing_host_validation, secret: "bla", target_url: "https://example.com/rdv-s-endpoint") }

    context "when the receiver responds with a 500 status" do
      before do
        stub_request(:post, "https://example.com/rdv-s-endpoint").and_return({ status: 500, body: "ERROR" })
      end

      it "retries up to 20 times but never notifies Sentry" do
        described_class.perform_later(payload, webhook_endpoint.id)

        expect(enqueued_jobs.first["executions"]).to eq(0)

        19.times { perform_enqueued_jobs }

        expect(enqueued_jobs.first["executions"]).to eq(19)

        expect { perform_enqueued_jobs }.to raise_error(WebhookJob::OutgoingWebhookError)
        expect(sentry_events).to be_empty
      end

      it "retries with a lower priority" do
        stub_request(:post, "https://example.com/rdv-s-endpoint").and_return({ status: 500, body: "ERROR" })
        described_class.perform_later(payload, webhook_endpoint.id)

        perform_enqueued_jobs
        expect(enqueued_jobs.first["priority"]).to eq(20)
      end
    end

    context "when there is an error in the application code" do
      let(:rdv) { create(:rdv) }

      before do
        stub_request(:post, "https://example.com/rdv-s-endpoint").and_return({ status: 200, body: "" })
        allow_any_instance_of(Rdv).to receive(:generate_webhook_payload).and_raise("Some error when generating the payload") # rubocop:disable RSpec/AnyInstance
      end

      it "retries and notifies sentry on the 3rd retry" do
        described_class.perform_later(record: rdv, action: :update, webhook_endpoint_id: webhook_endpoint.id)
        expect(sentry_events).to be_empty

        2.times { perform_enqueued_jobs }
        expect(sentry_events).to be_empty

        perform_enqueued_jobs
        expect(sentry_events.last.exception.values.last.value).to eq("Some error when generating the payload (RuntimeError)")
      end
    end

    it "retries on timeout" do
      stub_request(:post, "https://example.com/rdv-s-endpoint").to_timeout
      described_class.perform_later(payload, webhook_endpoint.id)

      perform_enqueued_jobs
      expect(enqueued_jobs.first["executions"]).to eq(1)
    end
  end
end
