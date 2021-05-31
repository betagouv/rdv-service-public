# frozen_string_literal: true

describe Notifications::Rdv::RdvCreatedService, type: :service do
  subject { described_class.perform_with(rdv) }

  let(:user1) { build(:user) }
  let(:user2) { build(:user) }
  let(:agent1) { build(:agent) }
  let(:agent2) { build(:agent) }
  let(:rdv) { create(:rdv, starts_at: starts_at, motif: motif, users: [user1, user2], agents: [agent1, agent2]) }

  before do
    allow(Users::RdvMailer).to receive(:rdv_created).and_return(instance_double(ActionMailer::MessageDelivery, deliver_later: nil))
    allow(Agents::RdvMailer).to receive(:rdv_created).and_return(instance_double(ActionMailer::MessageDelivery, deliver_later: nil))
  end

  context "starts in more than 2 days" do
    let(:starts_at) { 3.days.from_now }
    let(:motif) { build(:motif) }

    it "triggers sending mail to users but not to agents" do
      expect(Users::RdvMailer).to receive(:rdv_created).with(rdv, user1)
      expect(Users::RdvMailer).to receive(:rdv_created).with(rdv, user2)
      expect(Agents::RdvMailer).not_to receive(:rdv_created)
      subject
      expect(rdv.events.where(event_type: RdvEvent::TYPE_NOTIFICATION_MAIL, event_name: "created").count).to eq 2
    end
  end

  context "starts today or tomorrow" do
    let(:starts_at) { 2.hours.from_now }
    let(:motif) { build(:motif) }

    it "triggers sending mails to both user and agents" do
      expect(Users::RdvMailer).to receive(:rdv_created).with(rdv, user1)
      expect(Users::RdvMailer).to receive(:rdv_created).with(rdv, user2)
      expect(Agents::RdvMailer).to receive(:rdv_created).with(rdv, agent1)
      expect(Agents::RdvMailer).to receive(:rdv_created).with(rdv, agent2)
      subject
    end
  end

  context "with visible and not notified motif" do
    let(:starts_at) { 3.days.from_now }
    let(:motif) { build(:motif, :visible_and_not_notified) }

    it "does not send emails to users" do
      expect(Users::RdvMailer).not_to receive(:rdv_created)
      subject
    end
  end
end
