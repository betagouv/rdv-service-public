RSpec.describe "Handling an email reply from a user" do
  subject(:receive_sendinblue_callback) do
    post "/inbound_emails/sendinblue?password=#{password_param}",
         params: { items: [{ Subject: "Dummy email" }] }.to_json,
         headers: { "Content-Type" => "application/json" }
  end

  stub_env_with(SENDINBLUE_INBOUND_PASSWORD: "S3cr3T")

  context "when using a valid password" do
    let(:password_param) { "S3cr3T" }

    it "enqueues the job that handles transferring the email" do
      expect do
        receive_sendinblue_callback
      end.to have_enqueued_job(TransferEmailReplyJob).with({ "Subject" => "Dummy email" }).on_queue(:mailers)
    end
  end

  context "when using an invalid password" do
    let(:password_param) { "inv4l1d" }

    it "does not enqueue any job" do
      expect { receive_sendinblue_callback }.not_to have_enqueued_job
    end

    it "warns Sentry" do
      receive_sendinblue_callback
      expect(sentry_events.last.message).to eq("Sendinblue inbound controller was called without valid password")
    end
  end
end
