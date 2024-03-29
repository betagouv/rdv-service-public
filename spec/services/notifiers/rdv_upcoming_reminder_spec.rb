RSpec.describe Notifiers::RdvUpcomingReminder, type: :service do
  subject { described_class.perform_with(rdv, nil) }

  let!(:rdv) { create(:rdv, starts_at: 2.days.from_now, users: [user1, user2]) }
  let!(:user1) { create(:user) }
  let!(:user2) { create(:user) }
  let!(:user3) { create(:user) }
  let!(:participation1) { rdv.participations.where(user: user1).first }
  let!(:participation2) { rdv.participations.where(user: user2).first }

  before do
    stub_netsize_ok
  end

  it "sends an sms and an email" do
    subject
    expect_notifications_sent_for(rdv, user1, :rdv_upcoming_reminder)
    expect_notifications_sent_for(rdv, user2, :rdv_upcoming_reminder)
    expect_no_notifications_for(rdv, user3, :rdv_upcoming_reminder)
  end

  it "doesnt send email if user participation is excused" do
    participation1.update(status: "excused")
    subject
    expect_no_notifications_for_user(user1)
    expect_notifications_sent_for(rdv, user2, :rdv_upcoming_reminder)
  end

  it "doesnt send email if user participation is revoked" do
    participation1.update(status: "excused")
    participation2.update(status: "revoked")
    subject
    expect_no_notifications
  end

  it "participations_tokens_by_user_id attribute outputs the tokens" do
    allow(Devise.token_generator).to receive(:generate).and_return("t0k3n")
    notifier = described_class.new(rdv, nil)
    notifier.perform
    expect(notifier.participations_tokens_by_user_id).to eq({ user1.id => "t0k3n", user2.id => "t0k3n" })
  end
end
