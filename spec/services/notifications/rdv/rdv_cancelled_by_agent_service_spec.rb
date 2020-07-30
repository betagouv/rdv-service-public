describe Notifications::Rdv::RdvCancelledByAgentService, type: :service do
  subject { Notifications::Rdv::RdvCancelledByAgentService.perform_with(rdv) }
  let(:user1) { build(:user) }
  let(:rdv) { create(:rdv, starts_at: 3.days.from_now, users: [user1]) }

  it "sends an email" do
    expect(Users::RdvMailer).to receive(:rdv_cancelled_by_agent)
      .with(rdv, user1)
      .and_return(double(deliver_later: nil))
    subject
    expect(rdv.events.where(event_type: RdvEvent::TYPE_NOTIFICATION_MAIL, event_name: "cancelled_by_agent").count).to eq 1
  end

  it "sends a SMS" do
    expect(SendTransactionalSmsJob).to receive(:perform_later)
      .with(:rdv_cancelled, rdv.id, user1.id)
    subject
    expect(rdv.events.where(event_type: RdvEvent::TYPE_NOTIFICATION_SMS, event_name: "cancelled_by_agent").count).to eq 1
  end
end
