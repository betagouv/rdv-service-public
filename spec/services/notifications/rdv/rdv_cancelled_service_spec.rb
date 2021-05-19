# frozen_string_literal: true

describe Notifications::Rdv::RdvCancelledService, type: :service do
  context "starts in more than 2 days" do
    it "does not triggers sending mail to agents" do
      starts_at_initial = Time.zone.parse("2021-04-26 8h15")
      travel_to(starts_at_initial)

      agent1 = build(:agent, first_name: "Sean", last_name: "PAUL")
      agent2 = build(:agent)
      rdv =  create_rdv_skip_notify(starts_at: starts_at_initial + 3.days, agents: [agent1, agent2])

      PaperTrail.request.whodunnit = "[Agent] Sean PAUL"
      update_rdv_skip_notify!(rdv, status: :excused)

      expect(Agents::RdvMailer).not_to receive(:rdv_starting_soon_cancelled)
      described_class.perform_with(rdv)
    end
  end

  context "starts today or tomorrow" do
    it "triggers sending mails to the agents (except the one who initiated the change)" do
      starts_at_initial = Time.zone.parse("2021-04-29 8h15")
      travel_to(starts_at_initial)

      agent1 = build(:agent, first_name: "Sean", last_name: "PAUL")
      agent2 = build(:agent)
      rdv =  create_rdv_skip_notify(starts_at: starts_at_initial + 1.day, agents: [agent1, agent2])

      PaperTrail.request.whodunnit = "[Agent] Sean PAUL"
      update_rdv_skip_notify!(rdv, status: :excused)

      expect(Agents::RdvMailer).not_to receive(:rdv_starting_soon_cancelled)
        .with(rdv, agent1, "[Agent] Sean PAUL", starts_at_initial)
      allow(Agents::RdvMailer).to receive(:rdv_starting_soon_cancelled)
        .with(rdv, agent2, "[Agent] Sean PAUL")
        .and_return(double(deliver_later: nil))
      described_class.perform_with(rdv)
    end
  end
end
