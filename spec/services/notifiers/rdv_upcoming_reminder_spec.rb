# frozen_string_literal: true

describe Notifiers::RdvUpcomingReminder, type: :service do
  subject { described_class.perform_with(rdv, user1) }

  let(:user1) { build(:user) }
  let(:rdv) { create(:rdv, starts_at: 2.days.from_now) }
  let(:rdv_payload) { rdv.payload }
  let(:rdv_user) { create(:rdvs_user, user: user1, rdv: rdv) }
  let(:rdvs_users) { RdvsUser.where(id: rdv_user.id) }
  let(:token) { "123456" }

  before do
    allow(Users::RdvMailer).to receive(:rdv_upcoming_reminder).and_call_original
    allow(Users::RdvSms).to receive(:rdv_upcoming_reminder).and_call_original
    allow(rdv).to receive(:rdvs_users).and_return(rdvs_users)
    allow(rdvs_users).to receive(:where).and_return([rdv_user])
    allow(rdv_user).to receive(:new_raw_invitation_token).and_return(token)
  end

  it "sends an sms and an email" do
    expect(Users::RdvMailer).to receive(:rdv_upcoming_reminder).with(rdv_payload, user1, token)
    expect(Users::RdvSms).to receive(:rdv_upcoming_reminder).with(rdv, user1, token)
    subject
    expect(rdv.events.where(event_type: RdvEvent::TYPE_NOTIFICATION_MAIL, event_name: "upcoming_reminder").count).to eq 1
    expect(rdv.events.where(event_type: RdvEvent::TYPE_NOTIFICATION_SMS, event_name: "upcoming_reminder").count).to eq 1
  end

  it "outputs the tokens" do
    expect(subject.rdv_tokens_by_user_id).to eq({ user1.id => token })
  end
end
