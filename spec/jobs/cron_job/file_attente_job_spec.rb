RSpec.describe CronJob::FileAttenteJob do
  subject(:send_notifications) do
    described_class.perform_now
    file_attente.reload
  end

  around { |example| perform_enqueued_jobs { example.run } }

  let!(:user) { create(:user) }
  let!(:file_attente) { create(:file_attente, rdv: rdv, user: user) }
  let!(:rdv) { create(:rdv, starts_at: now + 2.weeks, lieu: lieu, motif: motif, users: [user], agents: [agent], organisation: organisation) }
  let!(:participation) { rdv.participations.last }
  let!(:plage_ouverture) { create(:plage_ouverture, first_day: now + 2.weeks, start_time: Tod::TimeOfDay.new(10), agent: agent, lieu: lieu, motifs: [motif], organisation: organisation) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let(:motif) { create(:motif, organisation: organisation) }
  let!(:organisation) { create(:organisation) }
  let(:now) { Time.zone.parse("01-01-2019 09:00 +0100") }

  before do
    stub_netsize_ok

    travel_to(now)
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
      expect(Users::FileAttenteSms).to receive(:new_creneau_available).with(rdv, user)
      subject
    end

    it "sends an email" do
      allow(Users::FileAttenteMailer).to receive(:with).and_call_original
      expect(Users::FileAttenteMailer).to receive(:with).with({ rdv:, user: })
      subject
    end

    context "when the user can be notified by sms but not by email" do
      let!(:user) { create(:user, notify_by_email: false) }

      it "sends an sms and updates the file_attente" do
        expect { send_notifications }.to change(file_attente, :last_creneau_sent_at).from(nil).to(now)
      end
    end

    context "when the rdv participant is a proche of the user to notify" do
      let!(:responsible) { create(:user) }
      let!(:user) { create(:user, :relative, responsible: responsible) }

      it "sends the notification to the responsible" do
        allow(Users::FileAttenteMailer).to receive(:with).and_call_original
        expect(Users::FileAttenteMailer).to receive(:with).with(hash_including(user: responsible))
        subject
      end
    end

    context "when the max number of notifications has already been sent" do
      let!(:file_attente) { create(:file_attente, rdv:, user:, notifications_sent: 3) }

      it "does not send notification" do
        expect { subject }.not_to change { file_attente.reload.notifications_sent }
        expect(Receipt.count).to eq 0
      end
    end

    context "when creneau was already sent" do
      before { file_attente.update(last_creneau_sent_at: now) }

      it "does not send notification" do
        expect(Users::FileAttenteSms).not_to receive(:new_creneau_available)
        expect(Users::FileAttenteMailer).not_to receive(:with)
        subject
      end
    end
  end

  context "without availabilities before rdv" do
    let!(:plage_ouverture2) { create(:plage_ouverture, first_day: Date.yesterday, lieu: lieu, agent: agent, motifs: [motif], organisation: organisation) }

    it "does not send notification" do
      expect(Users::FileAttenteSms).not_to receive(:new_creneau_available)
      expect(Users::FileAttenteMailer).not_to receive(:with)
      subject
    end
  end

  context "when creneau is too close to RDV" do
    let!(:plage_ouverture2) { create(:plage_ouverture, first_day: 2.weeks.from_now - 1.day, lieu: lieu, agent: agent, motifs: [motif], organisation: organisation) }

    it "does not send notification" do
      expect { subject }.not_to change(file_attente, :notifications_sent).from(0)
    end
  end
end
