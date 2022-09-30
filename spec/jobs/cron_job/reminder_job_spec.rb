# frozen_string_literal: true

RSpec.describe CronJob::ReminderJob, type: :job do
  subject { described_class.perform_now }

  let(:now) { Time.zone.parse("01-01-2019 09:00") }

  before do
    travel_to(now)
    freeze_time
  end

  context "single rdv the day after tomorrow" do
    let!(:rdv1) { create(:rdv, starts_at: 2.days.from_now) }

    it "calls notification service" do
      expect(Notifiers::RdvUpcomingReminder).to receive(:perform_with).with(rdv1, nil)
      subject
    end
  end

  context "2 rdvs in 2 days, 1 tomorrow" do
    let!(:rdv1) { create(:rdv, starts_at: 2.days.from_now) }
    let!(:rdv2) { create(:rdv, starts_at: 2.days.from_now) }
    let!(:rdv3) { create(:rdv, starts_at: 1.day.from_now) }

    it "calls notification service" do
      expect(Notifiers::RdvUpcomingReminder).to receive(:perform_with).with(rdv1, nil)
      expect(Notifiers::RdvUpcomingReminder).to receive(:perform_with).with(rdv2, nil)
      expect(Notifiers::RdvUpcomingReminder).not_to receive(:perform_with).with(rdv3, nil)
      subject
    end
  end

  context "rdv in 2 days but cancelled" do
    let!(:rdv1) { create(:rdv, :excused, starts_at: 2.days.from_now) }

    it "calls notification service" do
      expect(Notifiers::RdvUpcomingReminder).not_to receive(:perform_with)
      subject
    end
  end
end
