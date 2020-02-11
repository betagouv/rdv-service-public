require 'rails_helper'

RSpec.describe ReminderJob, type: :job do
  describe '#perform' do
    let(:now) { DateTime.parse("01-01-2019 09:00") }

    before do
      travel_to(now)
      freeze_time
    end

    after { ReminderJob.perform_now }

    context "with rdv after tomorrow" do
      let(:rdv) { create(:rdv, starts_at: 2.day.from_now) }

      before { rdv.reload }

      it 'should send an sms + email to after tomorrow rdv' do
        expect(RdvMailer).to receive(:send_reminder).with(rdv, rdv.users.first).and_return(double(deliver_later: nil))
        expect(TwilioTextMessenger).to receive(:new).with(:reminder, rdv, rdv.users.first, {}).and_call_original
      end

      it "should send only one email/sms" do
        expect(RdvMailer).to receive(:send_reminder).once.and_return(double(deliver_later: nil))
        expect(TwilioTextMessenger).to receive(:new).with(:reminder, rdv, rdv.users.first, {}).once.and_call_original
      end
      it "should send two emails+sms when two rdvs after tomorrow" do
        rdv2 = create(:rdv, starts_at: 50.hours.from_now)
        [rdv, rdv2].each do |rdv|
          expect(RdvMailer).to receive(:send_reminder).with(rdv, rdv.users.first).and_return(double(deliver_later: nil))
          expect(TwilioTextMessenger).to receive(:new).with(:reminder, rdv, rdv.users.first, {}).once.and_call_original
        end
      end
    end

    context "without rdv after tomorrow" do
      let(:start_dates) { [1.day.ago, now, 2.hours.from_now, 13.hours.from_now, 1.day.from_now, 5.day.from_now] }

      it "should not send sms+email" do
        start_dates.map { |date| create(:rdv, starts_at: date) }
        expect(RdvMailer).not_to receive(:send_reminder)
        expect(TwilioTextMessenger).not_to receive(:new).and_call_original
      end
    end
  end
end
