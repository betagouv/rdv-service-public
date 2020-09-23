describe Notifications::Rdv::RdvCancelledService, type: :service do
  subject { Notifications::Rdv::RdvCancelledService.perform_with(rdv) }
  let(:user1) { build(:user) }
  let(:agent1) { build(:agent, first_name: "Sean", last_name: "PAUL") }
  let(:agent2) { build(:agent) }
  let(:starts_at_initial) { 2.hours.from_now }
  let!(:rdv) { create_rdv_skip_notify(starts_at: starts_at_initial, users: [user1], agents: [agent1, agent2]) }

  before do
    PaperTrail.request.whodunnit = "[Agent] Sean PAUL"
    update_rdv_skip_notify!(rdv, status: :excused)
  end

  context "starts in more than 2 days" do
    let(:starts_at_initial) { 3.days.from_now }

    it "does not triggers sending mail to agents" do
      expect(Agents::RdvMailer).not_to receive(:rdv_starting_soon_cancelled)
      subject
    end
  end

  context "starts today or tomorrow" do
    it "triggers sending mails to the agents (except the one who initiated the change)" do
      expect(Agents::RdvMailer).not_to receive(:rdv_starting_soon_cancelled)
        .with(rdv, agent1, "[Agent] Sean PAUL", starts_at_initial)
      expect(Agents::RdvMailer).to receive(:rdv_starting_soon_cancelled)
        .with(rdv, agent2, "[Agent] Sean PAUL")
        .and_return(double(deliver_later: nil))
      subject
    end
  end
end
