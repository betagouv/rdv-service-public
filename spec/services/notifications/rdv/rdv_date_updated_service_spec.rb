# frozen_string_literal: true

describe Notifications::Rdv::RdvDateUpdatedService, type: :service do
  subject { described_class.perform_with(rdv, agent1) }

  let(:user1) { build(:user) }
  let(:user2) { build(:user) }
  let(:agent1) { build(:agent, first_name: "Sean", last_name: "PAUL") }
  let(:agent2) { build(:agent) }
  let(:rdv) { create(:rdv, starts_at: starts_at_initial, users: [user1, user2], agents: [agent1, agent2]) }
  let(:rdv_payload_for_users) { rdv.payload(:update, user1) }
  let(:rdv_payload_for_agents) { rdv.payload(:update, agent1) }

  before do
    rdv.update!(starts_at: 4.days.from_now)

    allow(Users::RdvMailer).to receive(:rdv_date_updated).and_return(instance_double(ActionMailer::MessageDelivery, deliver_later: nil))
    allow(Agents::RdvMailer).to receive(:rdv_date_updated).and_return(instance_double(ActionMailer::MessageDelivery, deliver_later: nil))
  end

  context "starts in more than 2 days" do
    let(:starts_at_initial) { 3.days.from_now }

    it "triggers sending mail to users but not to agents" do
      expect(Users::RdvMailer).to receive(:rdv_date_updated).with(rdv_payload_for_users, user1, starts_at_initial)
      expect(Users::RdvMailer).to receive(:rdv_date_updated).with(rdv_payload_for_users, user2, starts_at_initial)
      expect(Agents::RdvMailer).not_to receive(:rdv_date_updated)
      subject
      expect(rdv.events.where(event_type: RdvEvent::TYPE_NOTIFICATION_MAIL, event_name: "updated").count).to eq 2
    end
  end

  context "starts today or tomorrow" do
    let(:starts_at_initial) { 2.hours.from_now }

    it "triggers sending mails to both user and agents (except the one who initiated the change)" do
      expect(Users::RdvMailer).to receive(:rdv_date_updated).with(rdv_payload_for_users, user1, starts_at_initial)
      expect(Users::RdvMailer).to receive(:rdv_date_updated).with(rdv_payload_for_users, user2, starts_at_initial)
      expect(Agents::RdvMailer).not_to receive(:rdv_date_updated).with(rdv_payload_for_agents, agent1, agent1, starts_at_initial)
      expect(Agents::RdvMailer).to receive(:rdv_date_updated).with(rdv_payload_for_agents, agent2, agent1, starts_at_initial)
      subject
    end
  end
end
