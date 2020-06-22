describe Notifications::Rdv::RdvUpcomingReminderService, type: :service do
  subject { Notifications::Rdv::RdvUpcomingReminderService.perform_with(rdv) }

  let(:user1) { build(:user) }
  let(:rdv) { create(:rdv, starts_at: 2.days.from_now, users: [user1]) }

  it 'should send an sms and an email' do
    expect(Users::RdvMailer).to receive(:rdv_upcoming_reminder)
      .with(rdv, user1)
      .and_return(double(deliver_later: nil))
    expect(SmsSenderJob).to receive(:perform_later)
      .with(:reminder, rdv, user1)
    # .and_call_original
    subject
  end
end
