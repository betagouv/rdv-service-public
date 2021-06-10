# frozen_string_literal: true

describe Notifications::Rdv::RdvUpcomingReminderService, type: :service do
  subject { described_class.perform_with(rdv) }

  let(:user1) { build(:user) }
  let(:rdv) { create(:rdv, starts_at: 2.days.from_now, users: [user1]) }
  let(:rdv_payload) { rdv.payload }

  before do
    allow(Users::RdvMailer).to receive(:rdv_upcoming_reminder).and_return(instance_double(ActionMailer::MessageDelivery, deliver_later: nil))
    allow(SendTransactionalSmsJob).to receive(:perform_later)
  end

  it "sends an sms and an email" do
    expect(Users::RdvMailer).to receive(:rdv_upcoming_reminder).with(rdv_payload, user1)
    subject
    expect(rdv.events.where(event_type: RdvEvent::TYPE_NOTIFICATION_MAIL, event_name: "upcoming_reminder").count).to eq 1
    expect(rdv.events.where(event_type: RdvEvent::TYPE_NOTIFICATION_SMS, event_name: "upcoming_reminder").count).to eq 1
  end
end
