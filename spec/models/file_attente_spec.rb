# frozen_string_literal: true

describe FileAttente, type: :model do
  let(:now) { Time.zone.parse("01-01-2019 09:00 +0100") }

  before do
    stub_netsize_ok

    travel_to(now)
  end

  describe "#send_notifications" do
    subject do
      described_class.send_notifications
      file_attente.reload
    end

    let!(:organisation) { create(:organisation) }
    let(:motif) { create(:motif, organisation: organisation) }
    let!(:lieu) { create(:lieu, organisation: organisation) }
    let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
    let!(:plage_ouverture) { create(:plage_ouverture, first_day: now + 2.weeks, start_time: Tod::TimeOfDay.new(10), agent: agent, lieu: lieu, motifs: [motif], organisation: organisation) }
    let!(:rdv_user) { build(:rdvs_user, user: user, rdv: rdv) }
    let!(:rdv) { create(:rdv, starts_at: now + 2.weeks, lieu: lieu, motif: motif, users: [user], agents: [agent], organisation: organisation) }
    let!(:file_attente) { create(:file_attente, rdv: rdv, user: user) }
    let!(:user) { create(:user) }
    let!(:token) { "123456" }

    before do
      allow(RdvsUser).to receive(:find_by).and_return(rdv_user)
      allow(rdv_user).to receive(:new_raw_invitation_token).and_return(token)
    end

    context "with availabilities before rdv" do
      let!(:plage_ouverture2) { create(:plage_ouverture, first_day: 8.days.from_now, start_time: Tod::TimeOfDay.new(9), lieu: lieu, agent: agent, motifs: [motif], organisation: organisation) }

      it "increments notifications_sent" do
        expect { subject }.to change(file_attente, :notifications_sent).from(0).to(1)
      end

      it "saves last creneau sent" do
        expect { subject }.to change(file_attente, :last_creneau_sent_at).from(nil).to(now)
      end

      it "sends an sms" do
        allow(Users::FileAttenteSms).to receive(:new_creneau_available).and_call_original
        expect(Users::FileAttenteSms).to receive(:new_creneau_available).with(rdv, user, token)
        subject
      end

      it "sends an email" do
        allow(Users::FileAttenteMailer).to receive(:with).and_call_original
        expect(Users::FileAttenteMailer).to receive(:with).with({ rdv: rdv, user: user, token: token })
        subject
      end
    end

    context "without availabilities before rdv" do
      let!(:plage_ouverture2) { create(:plage_ouverture, first_day: Date.yesterday, lieu: lieu, agent: agent, motifs: [motif], organisation: organisation) }

      it "does not send notification" do
        subject
        expect(Users::FileAttenteSms).not_to receive(:new_creneau_available)
        expect(Users::FileAttenteMailer).not_to receive(:with)
        expect(rdv_user).not_to receive(:new_raw_invitation_token)
      end
    end

    context "when creneau was already sent" do
      let!(:plage_ouverture2) { create(:plage_ouverture, first_day: 1.day.from_now, start_time: Tod::TimeOfDay.new(9), lieu: lieu, agent: agent, motifs: [motif], organisation: organisation) }

      it "does not send notification" do
        file_attente.update(last_creneau_sent_at: now)
        file_attente.reload
        subject
        expect(Users::FileAttenteSms).not_to receive(:new_creneau_available)
        expect(Users::FileAttenteMailer).not_to receive(:with)
        expect(rdv_user).not_to receive(:new_raw_invitation_token)
      end
    end

    context "when creneau is too close to RDV" do
      let!(:plage_ouverture2) { create(:plage_ouverture, first_day: 2.weeks.from_now - 1.day, lieu: lieu, agent: agent, motifs: [motif], organisation: organisation) }

      it "does not send notification" do
        expect { subject }.not_to change(file_attente, :notifications_sent).from(0)
      end
    end
  end
end
