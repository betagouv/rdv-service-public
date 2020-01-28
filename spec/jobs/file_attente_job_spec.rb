require 'rails_helper'

RSpec.describe FileAttenteJob, type: :job do
  describe '#perform' do
    let(:now) { DateTime.parse("01-01-2019 09:00") }
    let(:plage_ouverture) { create(:plage_ouverture, first_day: now + 2.weeks, start_time: Tod::TimeOfDay.new(9)) }
    let(:rdv) { create(:rdv, starts_at: now + 2.weeks) }
    let(:file_attente) { create(:file_attente, rdv: rdv) }

    before do
      travel_to(now)
      freeze_time
    end

    after { FileAttenteJob.perform_now(rdv.users.first, rdv) }

    it 'should send an sms + rdv to rdv' do
      expect(FileAttenteMailer).to receive(:send_notification).with(rdv, rdv.users.first).and_return(double(deliver_later: nil))
      expect(TwilioTextMessenger).to receive(:new).with(:file_attente, rdv, rdv.users.first).and_call_original
    end
  end
end
