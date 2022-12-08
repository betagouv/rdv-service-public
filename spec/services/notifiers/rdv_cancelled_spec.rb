# frozen_string_literal: true

describe Notifiers::RdvCancelled, type: :service do
  subject { described_class.perform_with(rdv, author) }

  let(:agent1) { build(:agent) }
  let(:agent2) { build(:agent) }
  let(:user) { build(:user) }
  let(:rdv) { build(:rdv, starts_at: starts_at, agents: [agent1, agent2]) }
  let(:rdv_user) { create(:rdvs_user, user: user, rdv: rdv) }
  let(:rdvs_users) { RdvsUser.where(id: rdv_user.id) }

  before do
    stub_netsize_ok

    rdv.update!(status: new_status)

    allow(Agents::RdvMailer).to receive(:with).and_call_original
    allow(Users::RdvMailer).to receive(:with).and_call_original
    allow(rdv).to receive(:rdvs_users).and_return(rdvs_users)
  end

  context "cancellation by agent" do
    let(:author) { agent1 }
    let(:new_status) { :revoked }

    context "starts in more than 2 days" do
      let(:starts_at) { 3.days.from_now }

      it "only notifies the user" do
        expect(Agents::RdvMailer).not_to receive(:with).with({ rdv: rdv, agent: agent1, author: agent1 })
        expect(Agents::RdvMailer).not_to receive(:with).with({ rdv: rdv, agent: agent2, author: agent1 })
        expect(Users::RdvMailer).to receive(:with).with({ rdv: rdv, user: user, token: /^[A-Z0-9]{8}$/ })

        subject
      end

      it "rdv_users_tokens_by_user_id attribute outputs the tokens" do
        notifier = described_class.new(rdv, user)
        notifier.perform
        expect(notifier.rdv_users_tokens_by_user_id).to match(user.id => /^[A-Z0-9]{8}$/)
      end
    end

    context "starts today or tomorrow" do
      let(:starts_at) { 1.day.from_now }

      it "notifies the users and the other agents (not the author)" do
        expect(Agents::RdvMailer).not_to receive(:with).with({ rdv: rdv, agent: agent1, author: agent1 })
        expect(Agents::RdvMailer).to receive(:with).with({ rdv: rdv, agent: agent2, author: agent1 })
        expect(Users::RdvMailer).to receive(:with).with({ rdv: rdv, user: user, token: /^[A-Z0-9]{8}$/ })

        subject
      end
    end
  end

  context "cancellation by user" do
    let(:author) { user }
    let(:new_status) { :excused }
    let(:starts_at) { 1.day.from_now }

    it "notifies the user and the agents" do
      expect(Agents::RdvMailer).to receive(:with).with({ rdv: rdv, agent: agent1, author: user })
      expect(Agents::RdvMailer).to receive(:with).with({ rdv: rdv, agent: agent2, author: user })
      expect(Users::RdvMailer).to receive(:with).with({ rdv: rdv, user: user, token: /^[A-Z0-9]{8}$/ })

      subject
    end
  end
end
