RSpec.describe Notifiers::ParticipationCreated, type: :service do
  subject(:perform_notify) { described_class.perform_with(participation:, author:) }

  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, organisations: [organisation]) }
  let!(:user) { create(:user) }
  let(:participation) { rdv.participations.first }

  let(:now) { Time.zone.parse("2025-07-30 09:00") }

  before { travel_to now }

  shared_examples "envoie un email à l’usager" do
    specify do
      users_rdv_mailer_double = instance_double(Users::RdvMailer)
      allow(Users::RdvMailer).to receive(:with)
        .with(rdv:, user:, token: instance_of(String))
        .and_return(users_rdv_mailer_double)
      mail_double = double
      allow(users_rdv_mailer_double).to receive(:rdv_created).and_return(mail_double)
      expect(mail_double).to receive(:deliver_later)
      perform_notify
    end
  end

  shared_examples "n’envoie pas d’email à l’usager" do
    specify do
      expect(Users::RdvMailer).not_to receive(:with)
      perform_notify
    end
  end

  shared_examples "envoie un SMS à l’usager" do
    specify do
      sms_double = double
      allow(Users::RdvSms).to receive(:rdv_created)
        .with(rdv, user, participation.restricted_auth_token)
        .and_return(sms_double)
      expect(sms_double).to receive(:deliver_later)
      perform_notify
    end
  end

  shared_examples "n’envoie pas de SMS à l’usager" do
    specify do
      expect(Users::RdvSms).not_to receive(:rdv_created)
      perform_notify
    end
  end

  context "participation créée par un agent pour un RDV collectif dans plus de 2 jours" do
    let(:author) { agent }
    let!(:motif) { create(:motif, collectif: true, organisation:) }
    let!(:rdv) { create(:rdv, starts_at: now + 3.days, motif:, users: [user], organisation:) }

    it_behaves_like "envoie un email à l’usager"
    it_behaves_like "envoie un SMS à l’usager"
  end

  context "participation créée par l’usager pour un RDV collectif dans plus de 2 jours" do
    let(:author) { user }
    let!(:motif) { create(:motif, collectif: true, organisation:) }
    let!(:rdv) { create(:rdv, starts_at: now + 3.days, motif:, users: [user], organisation:) }

    it_behaves_like "envoie un email à l’usager"
    it_behaves_like "n’envoie pas de SMS à l’usager"
  end

  context "participation créée par l’usager pour un RDV collectif dans moins de 2 jours" do
    let(:author) { user }
    let!(:motif) { create(:motif, collectif: true, organisation:) }
    let!(:rdv) { create(:rdv, starts_at: now + 1.day, motif:, users: [user], organisation:) }

    it_behaves_like "envoie un email à l’usager"
    it_behaves_like "envoie un SMS à l’usager"
  end

  context "participation créée par l’usager pour un RDV collectif dans moins de 2 jours MAIS l’usager a des préférences configurées pour ne pas être notifié" do
    let(:author) { user }
    let!(:motif) { create(:motif, collectif: true, organisation:) }
    let!(:rdv) { create(:rdv, starts_at: now + 1.day, motif:, users: [user], organisation:) }

    before do
      allow(user).to receive(:notifiable_by_email?).and_return(false)
      allow(user).to receive(:notifiable_by_sms?).and_return(false)
    end

    it_behaves_like "n’envoie pas d’email à l’usager"
    it_behaves_like "n’envoie pas de SMS à l’usager"
  end

  context "RDV collectif mais la participation n'a pas encore de token" do
    let(:author) { agent }
    let!(:motif) { create(:motif, collectif: true, organisation:) }
    let!(:rdv) { create(:rdv, starts_at: now + 3.days, motif:, users: [user], organisation:) }

    before { participation.update_column(:restricted_auth_token, nil) } # rubocop:disable Rails/SkipsModelValidations

    it_behaves_like "envoie un email à l’usager"

    it "génère un token" do
      perform_notify
      expect(participation.reload.restricted_auth_token).not_to be_nil
    end
  end

  context "RDV non collectif" do
    let(:author) { agent }
    let!(:motif) { create(:motif, collectif: false, organisation:) }
    let!(:rdv) { create(:rdv, starts_at: now + 1.day, motif:, users: [user], organisation:) }

    it_behaves_like "n’envoie pas d’email à l’usager"
    it_behaves_like "n’envoie pas de SMS à l’usager"
  end

  context "RDV collectif dans le passé" do
    let(:author) { agent }
    let!(:motif) { create(:motif, collectif: true, organisation:) }
    let!(:rdv) { create(:rdv, starts_at: now - 1.day, motif:, users: [user], organisation:) }

    it_behaves_like "n’envoie pas d’email à l’usager"
    it_behaves_like "n’envoie pas de SMS à l’usager"
  end

  context "RDV collectif mais la participation est marquée comme « à ne pas notifier » dans la base de données" do
    let(:author) { agent }
    let!(:motif) { create(:motif, collectif: true, organisation:) }
    let!(:rdv) { create(:rdv, starts_at: now + 3.days, motif:, users: [user], organisation:) }

    before { allow(participation).to receive(:send_lifecycle_notifications?).and_return(false) }

    it_behaves_like "n’envoie pas d’email à l’usager"
    it_behaves_like "n’envoie pas de SMS à l’usager"
  end
end
