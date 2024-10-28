RSpec.describe Ants::SyncAppointmentJob do
  context "job mis en attente avec des arguments dépréciés" do
    let!(:user1) { create(:user, ants_pre_demande_number: "AABBCCDDEE") }
    let!(:user2) { create(:user, ants_pre_demande_number: nil) }
    let!(:user3) { create(:user, ants_pre_demande_number: "1020304050") }

    it "met en attente de nouveaux jobs avec les nouveaux arguments" do
      expect(described_class).to receive(:perform_later).with(ants_pre_demande_number: "AABBCCDDEE")
      expect(described_class).not_to receive(:perform_later).with(ants_pre_demande_number: nil)
      expect(described_class).to receive(:perform_later).with(ants_pre_demande_number: "1020304050")
      expect(described_class).to receive(:perform_later).with(ants_pre_demande_number: "FOOBARFOO1")

      described_class.perform_now(
        rdv_attributes: { id: 10, status: "canceled", users_ids: [user1.id, user2.id, user3.id], obsolete_ants_pre_demande_number: "FOOBARFOO1" },
        appointment_data: { meeting_point: "gare du nord" }
      )
    end
  end

  context "Nouveau RDV ANTS" do
    let!(:organisation) { create(:organisation, verticale: :rdv_mairie) }
    let!(:lieu) { create(:lieu, organisation:, name: "Mairie de Saumur") }
    let!(:motif) { create(:motif, motif_category: create(:motif_category, :passeport)) }
    let!(:user) { create(:user, ants_pre_demande_number: "A123456789", organisations: [organisation]) }
    let!(:rdv) { create(:rdv, motif:, users: [user], lieu:, organisation:, starts_at: Time.zone.parse("2020-04-20 08:00:00")) }

    before { travel_to(Time.zone.parse("2020-02-10")) } # le RDV est dans le futur

    it "créé un appointment" do
      allow(AntsApi).to receive(:status)
        .with(hash_including(ants_pre_demande_number: "A123456789"))
        .and_return({ "status" => "validated", "appointments" => [] })
      expect(AntsApi).not_to receive(:delete)
      expect(AntsApi).to receive(:create).with(hash_including(ants_pre_demande_number: "A123456789"))
      described_class.perform_now(ants_pre_demande_number: "A123456789")
    end
  end

  context "Synchro pour un RDV ANTS dans le passé" do
    let!(:organisation) { create(:organisation, verticale: :rdv_mairie) }
    let!(:lieu) { create(:lieu, organisation:, name: "Mairie de Saumur") }
    let!(:motif) { create(:motif, motif_category: create(:motif_category, :passeport)) }
    let!(:user) { create(:user, ants_pre_demande_number: "A123456789", organisations: [organisation]) }
    let!(:rdv) { create(:rdv, motif:, users: [user], lieu:, organisation:, starts_at: Time.zone.parse("2020-04-20 08:00:00")) }

    before { travel_to(Time.zone.parse("2020-06-30")) } # le RDV est dans le passé

    it "supprime l’appointment existant et n’en re-créé pas" do
      allow(AntsApi).to receive(:status)
        .with(hash_including(ants_pre_demande_number: "A123456789"))
        .and_return(
          {
            "status" => "validated",
            "appointments" => [
              {
                "management_url" => "https://www.rdv-mairie-test.localhost/users/rdvs/#{rdv.id}",
                "meeting_point" => "Mairie de Saumur",
                "meeting_point_id" => lieu.id,
                "appointment_date" => "2020-04-20 08:00:00",
              },
            ],
          }
        )
      expect(AntsApi).to receive(:delete)
        .with(
          {
            ants_pre_demande_number: "A123456789",
            meeting_point: "Mairie de Saumur",
            meeting_point_id: lieu.id,
            appointment_date: "2020-04-20 08:00:00",
          }
        )
      expect(AntsApi).not_to receive(:create)
      described_class.perform_now(ants_pre_demande_number: "A123456789")
    end
  end

  context "Synchro pour un ants_pre_demande_number correspondant à un usager ayant un RDV mais qui n’est pas un RDV ANTS" do
    let!(:organisation) { create(:organisation, verticale: :rdv_mairie) }
    let!(:lieu) { create(:lieu, organisation:, name: "Mairie de Saumur") }
    let!(:user) { create(:user, ants_pre_demande_number: "A123456789", organisations: [organisation]) }
    let!(:rdv) { create(:rdv, users: [user], lieu:, organisation:, starts_at: Time.zone.parse("2020-04-20 08:00:00")) }

    before { travel_to(Time.zone.parse("2020-03-10")) } # le RDV est dans le futur

    it "ne créé pas d’appointment" do
      allow(AntsApi).to receive(:status)
        .with(hash_including(ants_pre_demande_number: "A123456789"))
        .and_return({ "status" => "validated", "appointments" => [] })
      expect(AntsApi).not_to receive(:delete)
      expect(AntsApi).not_to receive(:create)
      described_class.perform_now(ants_pre_demande_number: "A123456789")
    end
  end
end
