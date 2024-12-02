RSpec.describe RdvUpcomingReminderJob do
  it "runs a Notifiers::RdvUpcomingReminder job" do
    rdv = build(:rdv, starts_at: 6.hours.from_now)

    expect(Notifiers::RdvUpcomingReminder).to receive(:perform_with).with(rdv, nil)
    described_class.perform_now(rdv)
    expect(sentry_events).to be_empty
  end

  context "when RDV already ended" do
    it "discards the job and does not warn Sentry" do
      past_rdv = build(:rdv, starts_at: 6.hours.ago)

      expect(sentry_events).to be_empty
      described_class.perform_now(past_rdv)
      expect(sentry_events).to be_empty
    end
  end
end
