RSpec.describe Ants::SyncAppointmentJob do
  context "job mis en attente avec des arguments dépréciés" do
    let!(:user1) { create(:user, ants_pre_demande_number: "AABBCCDDEE") }
    let!(:user2) { create(:user, ants_pre_demande_number: nil) }
    let!(:user3) { create(:user, ants_pre_demande_number: "1020304050") }

    it "met en attente de nouveaux jobs avec les nouveaux arguments" do
      expect(described_class).to receive(:perform_later).with(application_id: "AABBCCDDEE")
      expect(described_class).not_to receive(:perform_later).with(application_id: nil)
      expect(described_class).to receive(:perform_later).with(application_id: "1020304050")
      expect(described_class).to receive(:perform_later).with(application_id: "FOOBARFOO1")

      described_class.perform_now(
        rdv_attributes: { id: 10, status: "canceled", users_ids: [user1.id, user2.id, user3.id], obsolete_application_id: "FOOBARFOO1" },
        appointment_data: { meeting_point: "gare du nord" }
      )
    end
  end
end
