describe FileAttente, type: :model do

  describe '#send_notifications' do
    let(:now) { DateTime.parse("01-01-2019 09:00") }
    let!(:lieu) { create(:lieu) }
    let!(:plage_ouverture) { create(:plage_ouverture, first_day: now + 2.weeks, start_time: Tod::TimeOfDay.new(10)) }
    let!(:rdv) { create(:rdv, starts_at: now + 2.weeks, location: lieu.address, motif: plage_ouverture.motifs.first, agent_ids: [plage_ouverture.agent.id] ) }
    let!(:file_attente) { create(:file_attente, rdv: rdv) }

    before do
      travel_to(now)
      freeze_time
    end

    subject { FileAttente.send_notifications }

    context "with availabilities before rdv" do
      let!(:plage_ouverture_2) { create(:plage_ouverture, :daily, first_day: now) }

      it 'should increment notifications_sent' do
        expect do
          subject
          file_attente.reload
        end.to change(file_attente, :notifications_sent).from(0).to(1)
      end
      it 'should save last creneau sent' do
        expect do
          subject
          file_attente.reload
        end.to change(file_attente, :last_creneau_sent_starts_at).from(nil)
      end
      it 'should increment notifications_sent' do
        ActiveJob::Base.queue_adapter = :test
        expect{subject}.to have_enqueued_job(FileAttenteJob)
      end
    end

    context "without availabilities before rdv" do
      let!(:plage_ouverture_2) { create(:plage_ouverture, first_day: now - 1.day) }

      it 'should not send notification' do
        # debugger
        ActiveJob::Base.queue_adapter = :test
        expect{subject}.not_to have_enqueued_job(FileAttenteJob)
      end
    end

    context "when creneau was already sent" do
      let!(:plage_ouverture) { create(:plage_ouverture, first_day: now, start_time: Tod::TimeOfDay.new(9)) }

      it 'should not send notification' do
        file_attente.update(last_creneau_sent_starts_at: now)
        file_attente.reload
        ActiveJob::Base.queue_adapter = :test
        expect{subject}.not_to have_enqueued_job(FileAttenteJob)
      end
    end
  end
end
