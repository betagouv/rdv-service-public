RSpec.describe Notifiers::RdvCreated, type: :service do
  subject { described_class.perform_with(rdv, user1) }

  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:agent1) { create(:agent, rdv_notifications_level: :others) }
  let(:agent2) { create(:agent, rdv_notifications_level: :others) }
  let(:rdv) { create(:rdv, starts_at: starts_at, motif: motif, agents: [agent1, agent2], users: [user1, user2], organisation: motif.organisation) }
  let(:token1) { user1.participations.last.restricted_auth_token }
  let(:token2) { user2.participations.last.restricted_auth_token }

  before do
    stub_netsize_ok
    allow(Users::RdvMailer).to receive(:with).and_call_original
    allow(Agents::RdvMailer).to receive(:with).and_call_original
    allow(Users::RdvSms).to receive(:rdv_created).and_call_original
  end

  context "créé par un agent" do
    subject { described_class.perform_with(rdv, agent1) }

    let(:starts_at) { 3.days.from_now }
    let(:motif) { build(:motif) }

    it "déclenche l'envoi d'emails aux utilisateurs et aux autres agents" do
      expect(Users::RdvMailer).to receive(:with).with({ rdv: rdv, user: user1, token: token1 })
      expect(Users::RdvMailer).to receive(:with).with({ rdv: rdv, user: user2, token: token2 })
      expect(Agents::RdvMailer).to receive(:with).with({ rdv: rdv, agent: agent2, author: agent1 })
      expect(Agents::RdvMailer).not_to receive(:with).with({ rdv: rdv, agent: agent1, author: agent1 })
      subject
    end
  end

  context "commence dans plus de 2 jours" do
    let(:starts_at) { 3.days.from_now }
    let(:motif) { build(:motif) }

    it "déclenche l'envoi d'emails aux utilisateurs et aux agents" do
      expect(Users::RdvMailer).to receive(:with).with({ rdv: rdv, user: user1, token: token1 })
      expect(Users::RdvMailer).to receive(:with).with({ rdv: rdv, user: user2, token: token2 })
      expect(Agents::RdvMailer).to receive(:with).with({ rdv: rdv, agent: agent1, author: user1 })
      expect(Agents::RdvMailer).to receive(:with).with({ rdv: rdv, agent: agent2, author: user1 })
      subject
    end

    it "l'utilisateur reçoit un SMS de confirmation" do
      expect(Users::RdvSms).to receive(:rdv_created).with(rdv, user1, token1)
      expect(Users::RdvSms).to receive(:rdv_created).with(rdv, user2, token2)
      subject
    end

    it "l'attribut participations_tokens_by_user_id retourne les tokens pour les utilisateurs correspondants" do
      notifier = described_class.new(rdv, user1)
      notifier.perform
      expect(notifier.participations_tokens_by_user_id).to eq({ user1.id => token1, user2.id => token2 })
    end
  end

  context "commence aujourd'hui ou demain" do
    let(:starts_at) { 2.hours.from_now }
    let(:motif) { build(:motif) }

    it "déclenche l'envoi d'emails aux utilisateurs et aux agents" do
      expect(Users::RdvMailer).to receive(:with).with({ rdv: rdv, user: user1, token: token1 })
      expect(Users::RdvMailer).to receive(:with).with({ rdv: rdv, user: user2, token: token2 })
      expect(Agents::RdvMailer).to receive(:with).with({ rdv: rdv, agent: agent1, author: user1 })
      expect(Agents::RdvMailer).to receive(:with).with({ rdv: rdv, agent: agent2, author: user1 })
      subject
    end

    it "l'utilisateur reçoit un SMS de confirmation" do
      expect(Users::RdvSms).to receive(:rdv_created).with(rdv, user1, token1)
      expect(Users::RdvSms).to receive(:rdv_created).with(rdv, user2, token2)
      subject
    end
  end

  context "avec un motif visible et non notifié" do
    let(:starts_at) { 3.days.from_now }
    let(:motif) { build(:motif, :visible_and_not_notified) }

    it "n'envoie pas d'emails aux utilisateurs" do
      expect(Users::RdvMailer).not_to receive(:with)
      subject
    end
  end

  context "le rendez-vous est pris par un utilisateur" do
    subject { described_class.perform_with(rdv, user1) }

    let(:rdv) { create(:rdv, starts_at: starts_at, motif: motif, agents: [agent1], users: [user1], organisation: motif.organisation, created_by: user1) }
    let(:starts_at) { 3.days.from_now }
    let(:motif) { build(:motif) }

    it "l'utilisateur ne reçoit pas de SMS de confirmation" do
      expect(Users::RdvSms).not_to receive(:rdv_created)
      subject
    end

    context "le rendez-vous est pris moins de 48h avant" do
      let(:starts_at) { 1.day.from_now }

      it "l'utilisateur reçoit un SMS de confirmation" do
        expect(Users::RdvSms).to receive(:rdv_created).with(rdv, user1, token1)
        subject
      end
    end

    context "l’utilisateur ne s’est jamais connecté" do
      let(:user1) { create(:user, latest_login_at: nil) }

      it "l'utilisateur reçoit un SMS de confirmation" do
        expect(Users::RdvSms).to receive(:rdv_created).with(rdv, user1, token1)
        subject
      end
    end
  end
end
