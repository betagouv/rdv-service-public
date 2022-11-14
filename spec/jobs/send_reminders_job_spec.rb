# frozen_string_literal: true

RSpec.describe SendRemindersJob do
  context "when no error is met" do
    let!(:rdv) { create(:rdv, starts_at: 2.days.from_now) }

    it "calls notifier" do
      expect(Notifiers::RdvUpcomingReminder).to receive(:perform_with).with(rdv, nil)

      described_class.perform_later(rdv)
      perform_enqueued_jobs
    end
  end

  context "when notifier crashes" do
    let!(:rdv) { create(:rdv, starts_at: 30.minutes.ago) }

    before do
      allow(Notifiers::RdvUpcomingReminder).to receive(:perform_with).and_raise("woopsie")
    end

    stub_sentry_events

    it "sends notification to sentry and does not retry" do
      expect(enqueued_jobs.size).to eq(0)
      described_class.perform_later(rdv)
      expect(enqueued_jobs.size).to eq(1)

      perform_enqueued_jobs

      expect(sentry_events.last.exception.values.last.value).to eq("woopsie")
      expect(sentry_events.last.extra[:arguments][0]).to eq("gid://lapin/Rdv/#{rdv.id}")
      expect(enqueued_jobs.size).to eq(0) # no retry
    end
  end
end
