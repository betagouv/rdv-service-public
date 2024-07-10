RSpec.describe Notifiers::RdvUpdated, type: :service do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }

  before do
    stub_netsize_ok
  end

  context "update with agent change" do
    subject { described_class.perform_with(rdv, user1, old_agent_ids: [removed_agent.id, kept_agent.id]) }

    let(:kept_agent) { create(:agent) }
    let(:new_agent) { create(:agent) }
    let(:removed_agent) { create(:agent) }
    let(:rdv) { create(:rdv, starts_at: 5.days.from_now, agents: [removed_agent, kept_agent], users: [user1]) }

    before do
      rdv.update!(agents: [new_agent, kept_agent])
    end

    it "triggers sending mail to users but not to agents" do
      subject

      expect_notifications_sent_for(rdv, user1, :rdv_updated)
      expect_notifications_sent_for(rdv, new_agent, :rdv_created)
      expect_notifications_sent_for(rdv, kept_agent, :rdv_updated)
      expect_notifications_sent_for(rdv, removed_agent, :rdv_cancelled)
    end
  end

  context "update without agent change" do
    subject { described_class.perform_with(rdv, agent1, old_agent_ids: [agent1.id, agent2.id]) }

    let(:agent1) { build(:agent, first_name: "Sean", last_name: "PAUL") }
    let(:agent2) { build(:agent) }
    let(:rdv) { create(:rdv, starts_at: starts_at_initial, agents: [agent1, agent2], users: [user1, user2]) }

    before do
      rdv.update!(starts_at: 4.days.from_now)
    end

    context "starts in more than 2 days" do
      let(:starts_at_initial) { 3.days.from_now }

      it "triggers sending mail to users but not to agents" do
        subject

        expect_notifications_sent_for(rdv, user1, :rdv_updated)
        expect_notifications_sent_for(rdv, user2, :rdv_updated)
        expect_no_notifications_for(rdv, agent1, :rdv_updated)
      end

      it "participations_tokens_by_user_id attribute outputs the tokens" do
        allow(Devise.token_generator).to receive(:generate).and_return("t0k3n")
        notifier = described_class.new(rdv, agent1, old_agent_ids: [agent1.id])
        notifier.perform
        expect(notifier.participations_tokens_by_user_id).to eq({ user1.id => "t0k3n", user2.id => "t0k3n" })
      end
    end

    context "starts today or tomorrow" do
      let(:starts_at_initial) { 2.hours.from_now }

      it "triggers sending mails to both user and agents (except the one who initiated the change)" do
        subject

        expect_notifications_sent_for(rdv, user1, :rdv_updated)
        expect_notifications_sent_for(rdv, user2, :rdv_updated)
        expect_notifications_sent_for(rdv, agent2, :rdv_updated)
        expect_no_notifications_for(rdv, agent1, :rdv_updated)
      end

      it "doesnt send email if user participation is excused" do
        rdv.participations.where(user: user1).update(status: "excused")
        subject

        expect_notifications_sent_for(rdv, user2, :rdv_updated)
        expect_notifications_sent_for(rdv, agent2, :rdv_updated)
        expect_no_notifications_for(rdv, user1, :rdv_updated)
      end

      it "doesnt send email if user participation is revoked" do
        rdv.participations.where(user: user1).update(status: "revoked")
        subject

        expect_notifications_sent_for(rdv, user2, :rdv_updated)
        expect_notifications_sent_for(rdv, agent2, :rdv_updated)
        expect_no_notifications_for(rdv, user1, :rdv_updated)
      end
    end
  end
end
