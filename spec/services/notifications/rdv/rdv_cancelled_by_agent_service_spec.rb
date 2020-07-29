describe Notifications::Rdv::RdvCancelledByAgentService, type: :service do
  subject { Notifications::Rdv::RdvCancelledByAgentService.perform_with(rdv) }
  let(:user1) { build(:user) }
  let(:rdv) { create(:rdv, starts_at: 3.days.from_now, users: [user1]) }

  it 'calls RdvMailer to send email to user' do
    expect(Users::RdvMailer).to receive(:rdv_cancelled_by_agent)
      .with(rdv, user1)
      .and_return(double(deliver_later: nil))
    subject
  end

  it 'calls RdvMailer to send email to user' do
    expect(SendTransactionalSmsJob).to receive(:perform_later)
      .with(:rdv_cancelled, rdv.id, user1.id)
    subject
  end
end
