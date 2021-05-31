# frozen_string_literal: true

describe Notifications::Rdv::RdvCancelledService, type: :service do
  subject { described_class.perform_with(rdv, agent1) }

  let(:agent1) { build(:agent) }
  let(:agent2) { build(:agent) }
  let!(:rdv) { build(:rdv, starts_at: starts_at, agents: [agent1, agent2]) }

  before do
    rdv.update!(status: :excused)

    allow(Agents::RdvMailer).to receive(:rdv_cancelled).and_return(instance_double(ActionMailer::MessageDelivery, deliver_later: nil))
  end

  context "starts in more than 2 days" do
    let(:starts_at) { 3.days.from_now }

    it "does not triggers sending mail to agents" do
      expect(Agents::RdvMailer).not_to receive(:rdv_cancelled).with(rdv, agent1, agent1)
      expect(Agents::RdvMailer).not_to receive(:rdv_cancelled).with(rdv, agent2, agent1)

      subject
    end
  end

  context "starts today or tomorrow" do
    let(:starts_at) { 1.day.from_now }

    it "triggers sending mails to the agents (except the one who initiated the change)" do
      expect(Agents::RdvMailer).not_to receive(:rdv_cancelled).with(rdv, agent1, agent1)
      expect(Agents::RdvMailer).to receive(:rdv_cancelled).with(rdv, agent2, agent1)
      subject
    end
  end
end
