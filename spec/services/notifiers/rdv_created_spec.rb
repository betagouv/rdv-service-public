# frozen_string_literal: true

describe Notifiers::RdvCreated, type: :service do
  subject { described_class.perform_with(rdv, user1) }

  let(:motif) { build(:motif) }
  let(:user1) { build(:user) }
  let(:user2) { build(:user) }
  let(:agent1) { build(:agent, service: motif.service) }
  let(:agent2) { build(:agent, service: motif.service) }
  let(:rdv) { create(:rdv, starts_at: starts_at, motif: motif, agents: [agent1, agent2]) }
  let(:rdv_user1) { create(:rdvs_user, user: user1, rdv: rdv) }
  let(:rdv_user2) { create(:rdvs_user, user: user2, rdv: rdv) }
  let(:rdvs_users_relation) { RdvsUser.where(id: [rdv_user1.id, rdv_user2.id]) }
  let(:rdvs_users_array) { [rdv_user1, rdv_user2] }
  let(:token1) { "123456" }
  let(:token2) { "56789" }

  before do
    allow(Users::RdvMailer).to receive(:with).and_call_original
    allow(Agents::RdvMailer).to receive(:with).and_call_original
    allow(rdv).to receive(:rdvs_users).and_return(rdvs_users_relation)
    allow(rdvs_users_relation).to receive(:where).with(send_lifecycle_notifications: true)
      .and_return(rdvs_users_array.select(&:send_lifecycle_notifications))
    allow(rdv_user1).to receive(:new_raw_invitation_token).and_return(token1)
    allow(rdv_user2).to receive(:new_raw_invitation_token).and_return(token2)
  end

  context "starts in more than 2 days" do
    let(:starts_at) { 3.days.from_now }
    let(:motif) { build(:motif) }

    it "triggers sending mail to users but not to agents" do
      expect(Users::RdvMailer).to receive(:with).with({ rdv: rdv, user: user1, token: token1 })
      expect(Users::RdvMailer).to receive(:with).with({ rdv: rdv, user: user2, token: token2 })
      expect(Agents::RdvMailer).not_to receive(:with)
      subject
    end

    it "outputs the tokens" do
      expect(subject).to eq({ user1.id => token1, user2.id => token2 })
    end
  end

  context "starts today or tomorrow" do
    let(:starts_at) { 2.hours.from_now }
    let(:motif) { build(:motif) }

    it "triggers sending mails to both user and agents" do
      expect(Users::RdvMailer).to receive(:with).with({ rdv: rdv, user: user1, token: token1 })
      expect(Users::RdvMailer).to receive(:with).with({ rdv: rdv, user: user2, token: token2 })
      expect(Agents::RdvMailer).to receive(:with).with({ rdv: rdv, agent: agent1, author: user1 })
      expect(Agents::RdvMailer).to receive(:with).with({ rdv: rdv, agent: agent2, author: user1 })
      subject
    end
  end

  context "with visible and not notified motif" do
    let(:starts_at) { 3.days.from_now }
    let(:motif) { build(:motif, :visible_and_not_notified) }

    it "does not send emails to users" do
      expect(Users::RdvMailer).not_to receive(:with)
      subject
    end
  end
end
