# frozen_string_literal: true

RSpec.describe CronJob::ReminderJob, type: :job do
  subject(:perform_now) { described_class.perform_now }

  context "single rdv the day after tomorrow" do
    let!(:rdv1) { create(:rdv, starts_at: 2.days.from_now) }

    it "enqueues job to process it" do
      expect { perform_now }.to enqueue_job(SendRemindersJob).with(rdv1)
    end
  end

  context "2 rdvs in 2 days, 1 tomorrow" do
    let!(:rdv1) { create(:rdv, starts_at: 2.days.from_now) }
    let!(:rdv2) { create(:rdv, starts_at: 2.days.from_now) }
    let!(:rdv3) { create(:rdv, starts_at: 1.day.from_now) }

    it "enqueues job to process the RDVs in 2 days, not the one tomorrow" do
      expect { perform_now }.to(
        enqueue_job(SendRemindersJob).with(rdv1) & \
        enqueue_job(SendRemindersJob).with(rdv2)
      )

      expect(enqueued_jobs.size).to eq(2) # job for rdv3 not enqueued
    end
  end

  context "rdv in 2 days but cancelled" do
    let!(:rdv1) { create(:rdv, :excused, starts_at: 2.days.from_now) }

    it "calls notification service" do
      expect { perform_now }.not_to enqueue_job
    end
  end
end
