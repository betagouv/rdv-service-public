# frozen_string_literal: true

describe Notifications::Rdv::RdvDateUpdatedService, type: :service do
  subject { described_class.perform_with(rdv) }

  let(:user1) { build(:user) }
  let(:user2) { build(:user) }
  let(:agent1) { build(:agent, first_name: "Sean", last_name: "PAUL") }
  let(:agent2) { build(:agent) }
  let(:starts_at_initial) { 2.hours.from_now }
  let!(:rdv) { create_rdv_skip_notify(starts_at: starts_at_initial, users: [user1, user2], agents: [agent1, agent2]) }

  before do
    PaperTrail.request.whodunnit = "[Agent] Sean PAUL"
    update_rdv_skip_notify!(rdv, starts_at: 4.days.from_now)
  end

  context "starts in more than 2 days" do
    let(:starts_at_initial) { 3.days.from_now }

    it "triggers sending mail to users but not to agents" do
      allow(Users::RdvMailer).to receive(:rdv_created).with(rdv, user1).and_return(instance_double(ActionMailer::MessageDelivery, deliver_later: nil))
      allow(Users::RdvMailer).to receive(:rdv_created).with(rdv, user2).and_return(instance_double(ActionMailer::MessageDelivery, deliver_later: nil))
      expect(Agents::RdvMailer).not_to receive(:rdv_date_updated)
      subject
      expect(rdv.events.where(event_type: RdvEvent::TYPE_NOTIFICATION_MAIL, event_name: "updated").count).to eq 2
    end
  end

  context "starts today or tomorrow" do
    it "triggers sending mails to both user and agents (except the one who initiated the change)" do
      allow(Users::RdvMailer).to receive(:rdv_created).with(rdv, user1).and_return(instance_double(ActionMailer::MessageDelivery, deliver_later: nil))
      allow(Users::RdvMailer).to receive(:rdv_created).with(rdv, user2).and_return(instance_double(ActionMailer::MessageDelivery, deliver_later: nil))
      expect(Agents::RdvMailer).not_to receive(:rdv_date_updated)
        .with(rdv, agent1, "[Agent] Sean PAUL", starts_at_initial)
      allow(Agents::RdvMailer).to receive(:rdv_date_updated)
        .with(rdv, agent2, "[Agent] Sean PAUL", starts_at_initial)
        .and_return(instance_double(ActionMailer::MessageDelivery, deliver_later: nil))
      subject
    end
  end
end
