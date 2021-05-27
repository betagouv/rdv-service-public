# frozen_string_literal: true

describe FileAttente, type: :model do
  describe "#send_notifications" do
    subject do
      described_class.send_notifications
      file_attente.reload
    end

    let(:now) { DateTime.parse("01-01-2019 09:00 +0100") }
    let!(:organisation) { create(:organisation) }
    let(:motif) { create(:motif, organisation: organisation) }
    let!(:lieu) { create(:lieu, organisation: organisation) }
    let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
    let!(:plage_ouverture) { create(:plage_ouverture, first_day: now + 2.weeks, start_time: Tod::TimeOfDay.new(10), agent: agent, lieu: lieu, motifs: [motif], organisation: organisation) }
    let!(:rdv) { create(:rdv, starts_at: now + 2.weeks, lieu: lieu, motif: motif, agents: [agent], organisation: organisation) }
    let!(:file_attente) { create(:file_attente, rdv: rdv) }

    before do
      travel_to(now)
      freeze_time
    end

    context "with availabilities before rdv" do
      let!(:plage_ouverture2) { create(:plage_ouverture, first_day: 1.day.from_now, start_time: Tod::TimeOfDay.new(9), lieu: lieu, agent: agent, motifs: [motif], organisation: organisation) }

      it "increments notifications_sent" do
        expect { subject }.to change(file_attente, :notifications_sent).from(0).to(1)
      end

      it "saves last creneau sent" do
        expect { subject }.to change(file_attente, :last_creneau_sent_at).from(nil).to(now)
      end

      it "sends an sms" do
        expect(SendTransactionalSmsJob).to receive(:perform_later)
        subject
        expect(rdv.events.where(event_type: RdvEvent::TYPE_NOTIFICATION_SMS, event_name: "file_attente_creneaux_available").count).to eq 1
      end

      it "sends an email" do
        allow(Users::FileAttenteMailer).to receive(:new_creneau_available).with(rdv, rdv.users.first).and_return(instance_double(ActionMailer::MessageDelivery, deliver_later: nil))
        subject
        expect(rdv.events.where(event_type: RdvEvent::TYPE_NOTIFICATION_MAIL, event_name: "file_attente_creneaux_available").count).to eq 1
      end
    end

    context "without availabilities before rdv" do
      let!(:plage_ouverture2) { create(:plage_ouverture, first_day: Date.yesterday, lieu: lieu, agent: agent, motifs: [motif], organisation: organisation) }

      it "does not send notification" do
        subject
        expect(SendTransactionalSmsJob).not_to receive(:perform_later)
        expect(Users::FileAttenteMailer).not_to receive(:new_creneau_available)
      end
    end

    context "when creneau was already sent" do
      let!(:plage_ouverture2) { create(:plage_ouverture, first_day: 1.day.from_now, start_time: Tod::TimeOfDay.new(9), lieu: lieu, agent: agent, motifs: [motif], organisation: organisation) }

      it "does not send notification" do
        file_attente.update(last_creneau_sent_at: now)
        file_attente.reload
        subject
        expect(SendTransactionalSmsJob).not_to receive(:perform_later)
        expect(Users::FileAttenteMailer).not_to receive(:new_creneau_available)
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
