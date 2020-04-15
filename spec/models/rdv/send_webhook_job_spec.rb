describe Rdv, type: :model do
  include ActiveJob::TestHelper

  let!(:webhook_endpoint) { create(:webhook_endpoint) }

  after(:each) do
    clear_enqueued_jobs
  end

  describe '#send_web_hook' do
    let(:rdv) { create(:rdv) }

    it 'notifies on creation' do
      expect(WebhookJob).to receive(:perform_later).with(hash_including('event' => 'created'), webhook_endpoint.id)
      rdv.reload
    end

    it 'notifies on update' do
      rdv.reload

      expect(WebhookJob).to receive(:perform_later).with(hash_including('event' => 'updated'), webhook_endpoint.id)
      rdv.status = :excused
      rdv.save
    end

    it 'notifies on deletion' do
      rdv.reload

      expect(WebhookJob).to receive(:perform_later).with(hash_including('event' => 'destroyed'), webhook_endpoint.id)
      rdv.destroy
    end
  end
end
