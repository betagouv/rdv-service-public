describe WebhookDeliverable, type: :concern do
  include ActiveJob::TestHelper

  let!(:webhook_endpoint) { create(:webhook_endpoint) }

  after(:each) do
    clear_enqueued_jobs
  end

  RSpec::Matchers.define :json_payload_with_meta do |key, value|
    match do |actual|
      content = ActiveSupport::JSON.decode(actual)
      content['meta'][key] == value
    end
  end

  describe '#send_web_hook' do
    let(:rdv) { create(:rdv) }

    it 'notifies on creation' do
      expect(WebhookJob).to receive(:perform_later).with(json_payload_with_meta('event', 'created'), webhook_endpoint.id)
      rdv.reload
    end

    it 'notifies on update' do
      rdv.reload

      expect(WebhookJob).to receive(:perform_later).with(json_payload_with_meta('event', 'updated'), webhook_endpoint.id)
      rdv.status = :excused
      rdv.save
    end

    it 'notifies on deletion' do
      rdv.reload

      expect(WebhookJob).to receive(:perform_later).with(json_payload_with_meta('event', 'destroyed'), webhook_endpoint.id)
      rdv.destroy
    end
  end
end
