describe Rdv, type: :model do
  include ActiveJob::TestHelper

  before(:each) do
    create(:webhook)
  end

  after(:each) do
    clear_enqueued_jobs
  end

  describe '#send_web_hook' do
    let(:rdv) { create(:rdv) }

    describe 'default publication' do
      it 'publishes the default status' do
        expect(WebHookJob).to receive(:perform_later).with(hash_including('status' => 'unknown'), instance_of(Webhook))
        rdv.reload
      end
    end

    describe 'publication on update' do
      before { rdv.reload }

      it 'publishes the new status' do
        expect(WebHookJob).to receive(:perform_later).with(hash_including('status' => 'excused'), instance_of(Webhook))
        rdv.status = :excused
        rdv.save
      end

      it 'publishes the deleted status' do
        expect(WebHookJob).to receive(:perform_later).with(hash_including('status' => 'deleted'), instance_of(Webhook))

        rdv.destroy
      end
    end
  end
end
