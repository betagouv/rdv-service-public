RSpec.describe SmsJob do
  let!(:territory) { create(:territory) }
  let(:content) { "contenu du message" }

  def enqueue_sms_job
    described_class.perform_later(
      sender_name: "RdvSoli",
      phone_number: "0611223344",
      content: content,
      territory_id: territory.id,
      receipt_params: {}
    )
  end

  it "works with netsize" do
    stub_netsize_ok

    enqueue_sms_job
    perform_enqueued_jobs

    expected_body = {
      destinationAddress: "0611223344",
      maxConcatenatedMessages: "10",
      messageText: "contenu du message",
      originatingAddress: "RdvSoli",
      originatorTON: "1",
    }
    expect(WebMock).to have_requested(:post, "https://europe.ipx.com/restapi/v1/sms/send").with(body: expected_body)
  end

  describe "content processing" do
    let(:content) { "Ça, du maïs grillé !? Mon œil ! áâãçëẽêíïîĩóôõúûũÀÁÂÃÇÈËẼÊÌÍÏÎĨÒÓÔÕÙÚÛŨ" }

    it "removes exotic accents but preserves common ones" do
      stub_netsize_ok

      enqueue_sms_job
      perform_enqueued_jobs

      expected_content = "Ca, du mais grillé !? Mon oeil ! aaaceeeiiiiooouuuAAAACEEEEIIIIIOOOOUUUU"
      expect(WebMock).to have_requested(:post, "https://europe.ipx.com/restapi/v1/sms/send").with(body: match(ERB::Util.url_encode(expected_content)))
    end
  end

  describe "error logging" do
    it "only sends error to Sentry after 3rd error" do
      allow(SmsSender).to receive(:perform_with).and_raise("erreur inattendue")

      enqueue_sms_job

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

    it "does not warn sentry if RDV was deleted" do
      rdv = create(:rdv)
      described_class.perform_later(receipt_params: { rdv: rdv })
      rdv.destroy!
      expect { perform_enqueued_jobs }.to change(enqueued_jobs, :size).by(-1)
      expect(sentry_events).to be_empty
    end
  end
end
