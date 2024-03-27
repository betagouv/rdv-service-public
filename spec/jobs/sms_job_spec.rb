RSpec.describe SmsJob do
  let(:territory) { create(:territory, sms_provider: "netsize") }
  let(:rdv) { create(:rdv) }
  let(:user) { create(:user) }
  let(:receipt_params) { { event: "rdv_created", rdv: rdv, user: user } }

  describe "error logging" do
    it "only sends error to Sentry after 3rd error" do
      stub_request(:post, "https://europe.ipx.com/restapi/v1/sms/send")
        .to_timeout

      described_class.perform_later(
        sender_name: "RdvSoli",
        phone_number: "0611223344",
        content: "test",
        territory_id: territory.id,
        receipt_params: receipt_params
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
      expect(sentry_events.last.exception.values.last.type).to eq("SmsJob::SmsSenderFailure")
      expect(sentry_events.last.exception.values.last.value).to eq("NetSize timeout (SmsJob::SmsSenderFailure)")
    end
  end

  describe "sent content" do
    subject do
      described_class.formatted_content(content)
    end

    let(:rdv) { create(:rdv) }
    let(:user) { create(:user) }

    context "remove accents and weird chars" do
      let(:content) { "àáäâãèéëẽêìíïîĩòóöôõùúüûũñçÀÁÄÂÃÈÉËẼÊÌÍÏÎĨÒÓÖÔÕÙÚÜÛŨÑÇ" }

      it { is_expected.to eq("àaäaaèéeeeìiiiiòoöooùuüuuñcAAÄAAEÉEEEIIIIIOOÖOOUUÜUUÑÇ") }
    end

    context "oe character" do
      let(:content) { "Nœuds les mînes" }

      it { is_expected.to eq("Noeuds les mines") }
    end

    describe "instance name" do
      before { ENV["RDV_SOLIDARITES_INSTANCE_NAME"] = instance_name }

      after { ENV.delete("RDV_SOLIDARITES_INSTANCE_NAME") }

      let(:content) { "Contenu de test" }

      context "when instance name is blank" do
        let(:instance_name) { "" }

        it { is_expected.to eq("Contenu de test") }
      end

      context "when instance name is set" do
        let(:instance_name) { "TEST INSTANCE" }

        it { is_expected.to eq("TEST INSTANCE\nContenu de test") }
      end
    end
  end

  describe "receipt creation" do
    before do
      stub_netsize_ok
      described_class.perform_now(
        sender_name: "RdvSoli",
        phone_number: "0612345678",
        content: "content",
        territory_id: territory.id,
        receipt_params: receipt_params
      )
    end

    it "works" do
      receipt = Receipt.last
      expect(receipt).to have_attributes(
        event: "rdv_created",
        rdv: rdv,
        user: user,
        content: "content",
        sms_provider: "netsize"
      )
    end
  end
end
