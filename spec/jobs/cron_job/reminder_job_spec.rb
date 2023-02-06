# frozen_string_literal: true

RSpec.describe CronJob::ReminderJob, type: :job do
  subject(:perform_now) { described_class.perform_now }

  before do
    travel_to(Time.zone.parse("2019-01-01 03:00"))
  end

  context "single rdv the day after tomorrow at 10:30" do
    let!(:rdv) { create(:rdv, starts_at: Time.zone.parse("2019-01-03 10:30")) }

    it "enqueues reminder job today at 10:30" do
      expect { perform_now }.to have_enqueued_job(RdvUpcomingReminderJob).with(rdv).at(Time.zone.parse("2019-01-01 10:30"))
    end
  end

  context "2 rdvs in 2 days, 1 tomorrow" do
    # RDV tomorrow
    let!(:rdv_tomorrow1030) { create(:rdv, starts_at: Time.zone.parse("2019-01-02 10:30")) }

    # RDVs day after tomorrow
    let!(:rdv_day_after_tomorrow1030) { create(:rdv, starts_at: Time.zone.parse("2019-01-03 10:30")) }
    let!(:rdv_day_after_tomorrow1400) { create(:rdv, starts_at: Time.zone.parse("2019-01-03 14:00")) }

    # RDV in 3 days
    let!(:rdv_in_three_days1400) { create(:rdv, starts_at: Time.zone.parse("2019-01-04 14:00")) }

    it "enqueues jobs only for RDVs that happen the day after tomorrow" do
      expect { perform_now }
        .to have_enqueued_job(RdvUpcomingReminderJob).with(rdv_day_after_tomorrow1030).at(Time.zone.parse("2019-01-01 10:30"))
        .and have_enqueued_job(RdvUpcomingReminderJob).with(rdv_day_after_tomorrow1400).at(Time.zone.parse("2019-01-01 14:00"))

      expect(enqueued_jobs.size).to eq(2) # other RDVs not enqueued
    end
  end

  context "rdv in 2 days but cancelled" do
    let!(:cancelled_rdv_day_after_tomorrow1030) { create(:rdv, :excused, starts_at: Time.zone.parse("2019-01-03 10:30")) }

    it "does not enqueue any job" do
      expect { perform_now }.not_to have_enqueued_job
    end
  end
end
