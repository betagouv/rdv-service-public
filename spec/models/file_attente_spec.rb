describe FileAttente, type: :model do
  describe '#send_notifications' do
    let(:now) { DateTime.parse("01-01-2019 09:00 +0100") }
    let!(:lieu) { create(:lieu) }
    let!(:plage_ouverture) { create(:plage_ouverture, first_day: now + 2.weeks, start_time: Tod::TimeOfDay.new(10)) }
    let!(:rdv) { create(:rdv, starts_at: now + 2.weeks, location: lieu.address, motif: plage_ouverture.motifs.first, agent_ids: [plage_ouverture.agent.id]) }
    let!(:file_attente) { create(:file_attente, rdv: rdv) }

    before do
      travel_to(now)
      freeze_time
    end

    subject do
      FileAttente.send_notifications
      file_attente.reload
    end

    context "with availabilities before rdv" do
      let!(:plage_ouverture_2) { create(:plage_ouverture, first_day: 1.day.from_now, start_time: Tod::TimeOfDay.new(9)) }

      it 'should increment notifications_sent' do
        expect { subject }.to change(file_attente, :notifications_sent).from(0).to(1)
      end
      it 'should save last creneau sent' do
        expect { subject }.to change(file_attente, :last_creneau_sent_at).from(nil).to(now)
      end
      it 'should send an sms' do
        expect(TwilioSenderJob).to receive(:perform_later)
        subject
      end

      it 'should send an email' do
        expect(Users::FileAttenteMailer).to receive(:new_creneau_available).with(rdv, rdv.users.first).and_return(double(deliver_later: nil))
        subject
      end
    end

    context "without availabilities before rdv" do
      let!(:plage_ouverture_2) { create(:plage_ouverture, first_day: Date.yesterday) }

      it 'should not send notification' do
        subject
        expect(TwilioSenderJob).not_to receive(:perform_later)
        expect(Users::FileAttenteMailer).not_to receive(:new_creneau_available)
      end
    end

    context "when creneau was already sent" do
      let!(:plage_ouverture_2) { create(:plage_ouverture, first_day: 1.day.from_now, start_time: Tod::TimeOfDay.new(9)) }

      it 'should not send notification' do
        file_attente.update(last_creneau_sent_at: now)
        file_attente.reload
        subject
        expect(TwilioSenderJob).not_to receive(:perform_later)
        expect(Users::FileAttenteMailer).not_to receive(:new_creneau_available)
      end
    end

    context "when creneau is too close to RDV" do
      let!(:plage_ouverture_2) { create(:plage_ouverture, first_day: 2.weeks.from_now - 1.day) }

      it 'should not send notification' do
        expect { subject }.not_to change(file_attente, :notifications_sent).from(0)
      end
    end
  end
end
