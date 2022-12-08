# frozen_string_literal: true

describe Notifiers::RdvUpcomingReminder, type: :service do
  subject { described_class.perform_with(rdv, user1) }

  let(:user1) { build(:user) }
  let(:rdv) { create(:rdv, starts_at: 2.days.from_now) }
  let(:rdv_user) { create(:rdvs_user, user: user1, rdv: rdv) }
  let(:rdvs_users) { RdvsUser.where(id: rdv_user.id) }

  before do
    stub_netsize_ok

    allow(Users::RdvMailer).to receive(:with).and_call_original
    allow(Users::RdvSms).to receive(:rdv_upcoming_reminder).and_call_original
    allow(rdv).to receive(:rdvs_users).and_return(rdvs_users)
  end

  it "sends an sms and an email" do
    expect(Users::RdvMailer).to receive(:with).with({ rdv: rdv, user: user1, token: /^[A-Z0-9]{8}$/ })
    expect(Users::RdvSms).to receive(:rdv_upcoming_reminder).with(rdv, user1, /^[A-Z0-9]{8}$/)
    subject
  end

  it "doesnt send email if user participation is excused" do
    rdv_user.update(status: "excused")
    expect(Users::RdvMailer).not_to receive(:with).with({ rdv: rdv, user: user1, token: /^[A-Z0-9]{8}$/ })
    expect(Users::RdvSms).not_to receive(:rdv_upcoming_reminder).with(rdv, user1, /^[A-Z0-9]{8}$/)
    subject
  end

  it "rdv_users_tokens_by_user_id attribute outputs the tokens" do
    notifier = described_class.new(rdv, user1)
    notifier.perform
    expect(notifier.rdv_users_tokens_by_user_id).to match(user1.id => /^[A-Z0-9]{8}$/)
  end
end
