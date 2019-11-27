require 'rails_helper'

RSpec.describe ReminderJob, type: :job do
  describe '#perform' do
    let(:now) { DateTime.parse("01-01-2019 09:00") }
    let(:start_dates) { [1.day.ago, now, 2.hours.from_now, 13.hours.from_now, 2.day.from_now, 5.day.from_now] }
    let(:rdv_tomorrow) { create(:rdv, starts_at: 1.day.from_now) }

    before do
      travel_to(now)
      freeze_time
      start_dates.each { |date| create(:rdv, starts_at: date) }
      rdv_tomorrow.reload
    end

    after { ReminderJob.perform_now }

    it 'should send an email to tomorrow rdv' do
      expect(RdvMailer).to receive(:send_reminder).with(rdv_tomorrow, rdv_tomorrow.users.first).and_return(double(deliver_later: nil))
    end

    it "should send only one email" do
      expect(RdvMailer).to receive(:send_reminder).once.and_return(double(deliver_later: nil))
    end

    it "should send two emails when two rdvs tomorrow" do
      rdv_tomorrow2 = create(:rdv, starts_at: 30.hours.from_now)
      expect(RdvMailer).to receive(:send_reminder).with(rdv_tomorrow, rdv_tomorrow.users.first).and_return(double(deliver_later: nil))
      expect(RdvMailer).to receive(:send_reminder).with(rdv_tomorrow2, rdv_tomorrow2.users.first).and_return(double(deliver_later: nil))
    end
  end
end
