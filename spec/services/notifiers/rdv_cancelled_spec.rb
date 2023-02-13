# frozen_string_literal: true

describe Notifiers::RdvCancelled, type: :service do
  subject { described_class.perform_with(rdv, author) }

  let!(:agent1) { create(:agent) }
  let!(:agent2) { create(:agent) }
  let!(:user1) { create(:user) }
  let!(:user2) { create(:user) }
  let!(:rdv) { create(:rdv, starts_at: starts_at, agents: [agent1, agent2], users: [user1, user2]) }
  let!(:rdv_user1) { rdv.rdvs_users.where(user: user1).first }
  let!(:rdv_user2) { rdv.rdvs_users.where(user: user2).first }

  before do
    stub_netsize_ok
    rdv.update!(status: new_status)
  end

  context "cancellation by agent" do
    let!(:author) { agent1 }
    let!(:new_status) { :revoked }

    context "starts in more than 2 days" do
      let(:starts_at) { 3.days.from_now }

      it "only notifies the user" do
        subject
        expect_notifications_sent_for(rdv, user1, :rdv_cancelled)
        expect_notifications_sent_for(rdv, user2, :rdv_cancelled)
        expect_no_notifications_for(rdv, agent1, :rdv_cancelled)
        expect_no_notifications_for(rdv, agent2, :rdv_cancelled)
      end

      it "rdv_users_tokens_by_user_id attribute outputs the tokens" do
        allow(Devise.token_generator).to receive(:generate).and_return("t0k3n")
        notifier = described_class.new(rdv, nil)
        notifier.perform
        expect(notifier.rdv_users_tokens_by_user_id).to eq({ user1.id => "t0k3n", user2.id => "t0k3n" })
      end
    end

    context "starts today or tomorrow" do
      let(:starts_at) { 1.day.from_now }

      it "notifies the users and the other agents (not the author)" do
        subject
        expect_notifications_sent_for(rdv, user1, :rdv_cancelled)
        expect_notifications_sent_for(rdv, user2, :rdv_cancelled)
        expect_notifications_sent_for(rdv, agent2, :rdv_cancelled)
        expect_no_notifications_for(rdv, agent1, :rdv_cancelled)
      end
    end
  end

  context "cancellation by user" do
    let!(:author) { user1 }
    let!(:new_status) { :excused }
    let!(:starts_at) { 1.day.from_now }

    it "notifies the user and the agents only by mails" do
      subject
      # Excused rdvs when author is a user doesnt notify users by sms
      expect_notifications_sent_for(rdv, user1, :rdv_cancelled, :mail)
      expect_notifications_sent_for(rdv, user2, :rdv_cancelled, :mail)
      expect_notifications_sent_for(rdv, agent1, :rdv_cancelled)
      expect_notifications_sent_for(rdv, agent2, :rdv_cancelled)
    end
  end
end
