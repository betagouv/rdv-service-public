# frozen_string_literal: true

describe Notifications::Rdv::RdvCancelledService, type: :service do
  subject { described_class.perform_with(rdv, author) }

  let(:agent1) { build(:agent) }
  let(:agent2) { build(:agent) }
  let(:user) { build(:user) }
  let(:rdv) { build(:rdv, starts_at: starts_at, users: [user], agents: [agent1, agent2]) }
  let(:rdv_payload) { rdv.payload(:destroy) }

  before do
    rdv.update!(status: :excused)

    allow(Agents::RdvMailer).to receive(:rdv_cancelled).and_return(instance_double(ActionMailer::MessageDelivery, deliver_later: nil))
    allow(Users::RdvMailer).to receive(:rdv_cancelled).and_return(instance_double(ActionMailer::MessageDelivery, deliver_later: nil))
  end

  context "cancellation by agent" do
    let(:author) { agent1 }

    context "starts in more than 2 days" do
      let(:starts_at) { 3.days.from_now }

      it "only notifies the user" do
        expect(Agents::RdvMailer).not_to receive(:rdv_cancelled).with(rdv_payload, agent1, agent1)
        expect(Agents::RdvMailer).not_to receive(:rdv_cancelled).with(rdv_payload, agent2, agent1)
        expect(Users::RdvMailer).to receive(:rdv_cancelled).with(rdv_payload, user, agent1)

        subject
        expect(rdv.events.where(event_type: RdvEvent::TYPE_NOTIFICATION_MAIL, event_name: "cancelled_by_agent").count).to eq 1
        expect(rdv.events.where(event_type: RdvEvent::TYPE_NOTIFICATION_SMS, event_name: "cancelled_by_agent").count).to eq 1
      end
    end

    context "starts today or tomorrow" do
      let(:starts_at) { 1.day.from_now }

      it "notifies the users and the other agents (not the author)" do
        expect(Agents::RdvMailer).not_to receive(:rdv_cancelled).with(rdv_payload, agent1, agent1)
        expect(Agents::RdvMailer).to receive(:rdv_cancelled).with(rdv_payload, agent2, agent1)
        expect(Users::RdvMailer).to receive(:rdv_cancelled).with(rdv_payload, user, agent1)

        subject
        expect(rdv.events.where(event_type: RdvEvent::TYPE_NOTIFICATION_MAIL, event_name: "cancelled_by_agent").count).to eq 1
        expect(rdv.events.where(event_type: RdvEvent::TYPE_NOTIFICATION_SMS, event_name: "cancelled_by_agent").count).to eq 1
      end
    end
  end

  context "cancellation by user" do
    let(:author) { user }
    let(:starts_at) { 1.day.from_now }

    it "notifies the user and the agents" do
      expect(Agents::RdvMailer).to receive(:rdv_cancelled).with(rdv_payload, agent1, user)
      expect(Agents::RdvMailer).to receive(:rdv_cancelled).with(rdv_payload, agent2, user)
      expect(Users::RdvMailer).to receive(:rdv_cancelled).with(rdv_payload, user, user)

      subject
      expect(rdv.events.where(event_type: RdvEvent::TYPE_NOTIFICATION_MAIL, event_name: "cancelled_by_user").count).to eq 1
    end
  end
end
