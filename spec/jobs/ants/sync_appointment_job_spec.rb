RSpec.describe Ants::SyncAppointmentJob do
  describe "#perform_later_for" do
    context "usager unique avec un application_id" do
      let!(:lieu) { create(:lieu, name: "MDS Nord") }
      let!(:user) { create(:user, ants_pre_demande_number: "BASDFE34") }
      let!(:rdv) { create(:rdv, starts_at: Time.zone.parse("2024-09-27 16:30:00"), lieu:, users: [user]) }

      it "met en attente une seule synchronisation" do
        expect(described_class).to receive(:perform_later)
          .once
          .with(
            rdv_attributes: {
              id: rdv.id,
              status: "unknown",
              host_name: "www.rdv-solidarites-test.localhost",
              lieu_name: "MDS Nord",
              lieu_id: lieu.id,
              starts_at: "2024-09-27 16:30:00",
            },
            application_id: "BASDFE34"
          )
        described_class.perform_later_for(rdv)
      end
    end

    context "4 usagers dont 2 avec des application_id différents" do
      let!(:lieu) { create(:lieu, name: "MDS Nord") }
      let!(:user1) { create(:user, ants_pre_demande_number: "BASDFE34") }
      let!(:user2) { create(:user, ants_pre_demande_number: "CIE213XZ") }
      let!(:user3) { create(:user, ants_pre_demande_number: nil) }
      let!(:user4) { create(:user, ants_pre_demande_number: "BASDFE34") }
      let!(:rdv) { create(:rdv, starts_at: Time.zone.parse("2024-09-27 16:30:00"), lieu:, users: [user1, user2, user3, user4]) }

      it "met en attente deux synchronisations" do
        rdv_attributes = {
          id: rdv.id,
          status: "unknown",
          host_name: "www.rdv-solidarites-test.localhost",
          lieu_name: "MDS Nord",
          lieu_id: lieu.id,
          starts_at: "2024-09-27 16:30:00",
        }
        expect(described_class).to receive(:perform_later)
          .once.with({ rdv_attributes:, application_id: "BASDFE34" })
        expect(described_class).to receive(:perform_later)
          .once.with({ rdv_attributes:, application_id: "CIE213XZ" })
        described_class.perform_later_for(rdv)
      end
    end
  end

  describe "#perform" do
    context "RDV supprimé entre-temps" do
      # pour simuler la suppression du RDV, on ne créé simplement pas de RDV du tout et on passe un id fictif
      it "supprime l’appointment" do
        allow(AntsApi).to receive(:status)
          .with(hash_including(application_id: "CIE213XZ"))
          .and_return({ "status" => "validated" })
        expect(AntsApi).to receive(:find_and_delete)
          .once.with(
            {
              application_id: "CIE213XZ",
              management_url: "http://www.rdv-solidarites-test.localhost/users/rdvs/3?ants_pre_demande_number=CIE213XZ",
            }
          )
        expect(AntsApi).not_to receive(:create)
        described_class.new.perform(
          rdv_attributes: {
            id: 3,
            status: "unknown",
            host_name: "www.rdv-solidarites-test.localhost",
            lieu_name: "MDS Nord",
            lieu_id: 40,
            starts_at: "2024-09-27 16:30:00",
          },
          application_id: "CIE213XZ"
        )
      end
    end

    context "RDV est à mettre à jour" do
      let!(:lieu) { create(:lieu, name: "MDS Nord") }
      let!(:rdv) { create(:rdv, status: "unknown", lieu:, starts_at: Time.zone.parse("2024-09-27 16:30:00")) }

      it "supprime puis recréé l’appointment" do
        allow(AntsApi).to receive(:status)
          .with(hash_including(application_id: "CIE213XZ"))
          .and_return({ "status" => "validated" })
        expect(AntsApi).to receive(:find_and_delete)
          .once.with(
            {
              application_id: "CIE213XZ",
              management_url: "http://www.rdv-solidarites-test.localhost/users/rdvs/#{rdv.id}?ants_pre_demande_number=CIE213XZ",
            }
          )
        expect(AntsApi).to receive(:create)
          .once.with(
            {
              application_id: "CIE213XZ",
              appointment_date: "2024-09-27 16:30:00",
              meeting_point: "MDS Nord",
              meeting_point_id: lieu.id.to_s,
              management_url: "http://www.rdv-solidarites-test.localhost/users/rdvs/#{rdv.id}?ants_pre_demande_number=CIE213XZ",
            }
          )
        described_class.new.perform(
          rdv_attributes: {
            id: rdv.id,
            status: "unknown",
            host_name: "www.rdv-solidarites-test.localhost",
            lieu_name: "MDS Nord",
            lieu_id: lieu.id,
            starts_at: "2024-09-27 16:30:00",
          },
          application_id: "CIE213XZ"
        )
      end
    end

    context "le statut de l’appointment sur l’ANTS n’est pas valide" do
      let!(:lieu) { create(:lieu, name: "MDS Nord") }
      let!(:rdv) { create(:rdv, status: "unknown", lieu:, starts_at: Time.zone.parse("2024-09-27 16:30:00")) }

      it "ne supprime ni ne recréé l’appointment" do
        allow(AntsApi).to receive(:status)
          .with(hash_including(application_id: "CIE213XZ"))
          .and_return({ "status" => "broken" })
        expect(AntsApi).not_to receive(:find_and_delete)
        expect(AntsApi).not_to receive(:create)
        described_class.new.perform(
          rdv_attributes: {
            id: rdv.id,
            status: "unknown",
            host_name: "www.rdv-solidarites-test.localhost",
            lieu_name: "MDS Nord",
            lieu_id: lieu.id,
            starts_at: "2024-09-27 16:30:00",
          },
          application_id: "CIE213XZ"
        )
      end
    end
  end
end
