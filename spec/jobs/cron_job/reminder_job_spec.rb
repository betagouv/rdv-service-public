# frozen_string_literal: true

RSpec.describe CronJob::ReminderJob, type: :job do
  subject(:perform_now) { described_class.perform_now }

  let(:now) { Time.zone.parse("01-01-2019 14:57") }

  before do
    travel_to(now)
    freeze_time
  end

  context "single rdv in 48 to 49 hours" do
    let!(:rdv_in_48_hours_and_30_minutes) { create(:rdv, starts_at: 48.hours.from_now + 30.minutes) }

    it "calls notification service" do
      expect(Notifiers::RdvUpcomingReminder).to receive(:perform_with).with(rdv_in_48_hours_and_30_minutes, nil)
      perform_now
    end
  end

  context "RDVs before 48 hours, within 48-49 hours, after 49 hours" do
    # RDVs in the pas
    let!(:rdv_2_days_ago) { create(:rdv, starts_at: 2.days.ago) }
    let!(:rdv_in_10_minutes) { create(:rdv, starts_at: 10.minutes.from_now) }
    let!(:rdv_in_47_hours_and_30_minutes) { create(:rdv, starts_at: 47.hours.from_now + 30.minutes) }

    # RDVs in about 48 hours
    let!(:rdv_in_48_hours_and_10_minutes) { create(:rdv, starts_at: 48.hours.from_now + 10.minutes) }
    let!(:rdv_in_48_hours_and_30_minutes) { create(:rdv, starts_at: 48.hours.from_now + 30.minutes) }

    # RDVs after 49 hours
    let!(:rdv_in_49_hours_and_30_minutes) { create(:rdv, starts_at: 49.hours.from_now + 30.minutes) }
    let!(:rdv_in_2_weeks) { create(:rdv, starts_at: 2.weeks.from_now) }

    it "calls notification service" do
      expect(Notifiers::RdvUpcomingReminder).not_to receive(:perform_with).with(rdv_2_days_ago, nil)
      expect(Notifiers::RdvUpcomingReminder).not_to receive(:perform_with).with(rdv_in_10_minutes, nil)
      expect(Notifiers::RdvUpcomingReminder).not_to receive(:perform_with).with(rdv_in_47_hours_and_30_minutes, nil)

      expect(Notifiers::RdvUpcomingReminder).to receive(:perform_with).with(rdv_in_48_hours_and_10_minutes, nil)
      expect(Notifiers::RdvUpcomingReminder).to receive(:perform_with).with(rdv_in_48_hours_and_30_minutes, nil)

      expect(Notifiers::RdvUpcomingReminder).not_to receive(:perform_with).with(rdv_in_49_hours_and_30_minutes, nil)
      expect(Notifiers::RdvUpcomingReminder).not_to receive(:perform_with).with(rdv_in_2_weeks, nil)

      perform_now
    end
  end

  context "rdv in the right time scope bu cancelled" do
    let!(:rdv_in_48_hours_and_30_minutes) { create(:rdv, :excused, starts_at: 48.hours.from_now + 30.minutes) }

    it "does not call notification service" do
      expect(Notifiers::RdvUpcomingReminder).not_to receive(:perform_with)
      perform_now
    end
  end

  describe "error handling" do
    let!(:rdv1) { create(:rdv, starts_at: 2.days.from_now) }
    let!(:rdv2) { create(:rdv, starts_at: 2.days.from_now) }
    let!(:rdv3) { create(:rdv, starts_at: 2.days.from_now) }

    stub_sentry_events

    it "does not stop on first error" do
      # Something unexpected happens when processing rdv2
      allow(Notifiers::RdvUpcomingReminder).to receive(:perform_with).with(rdv2, nil).and_raise("woopsie")

      expect(Notifiers::RdvUpcomingReminder).to receive(:perform_with).with(rdv1, nil)
      expect(Notifiers::RdvUpcomingReminder).to receive(:perform_with).with(rdv2, nil)
      expect(Notifiers::RdvUpcomingReminder).to receive(:perform_with).with(rdv3, nil)

      perform_now

      # Exception raised by rdv_2 is sent to Sentry
      expect(sentry_events.last.exception.values.last.value).to eq("woopsie (RuntimeError)")
      expect(sentry_events.last.breadcrumbs.compact.first.data[:rdv_id]).to eq(rdv2.id)
    end
  end
end
