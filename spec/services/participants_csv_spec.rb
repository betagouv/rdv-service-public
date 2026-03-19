RSpec.describe ParticipantsCsv, type: :service do
  before { travel_to Time.zone.parse("2026-03-19 08:00") }

  let(:organisation) { create(:organisation) }
  let(:rdv) do
    create(:rdv, :collectif, :without_users, organisation: organisation, starts_at: Time.zone.parse("2027-06-15 10:00"))
  end

  describe "#filename" do
    it "includes the RDV date" do
      expect(described_class.new(rdv).filename).to eq("participants-rdv-collectif-2027-06-15.csv")
    end
  end

  describe "#generate_csv" do
    let!(:user1) { create(:user, first_name: "Alice", last_name: "Martin", email: "alice@example.com", organisations: [organisation]) }
    let!(:user2) { create(:user, first_name: "Bob", last_name: "Dupont", email: "bob@example.com", organisations: [organisation]) }

    before do
      create(:participation, rdv: rdv, user: user1, created_at: 2.minutes.ago)
      create(:participation, rdv: rdv, user: user2, created_at: 1.minute.ago)
    end

    it "returns a CSV with headers and one row per participation, ordered by creation date" do
      expected_csv = <<~CSV
        full_name,email,status
        Alice MARTIN,alice@example.com,Rendez-vous à venir
        Bob DUPONT,bob@example.com,Rendez-vous à venir
      CSV
      expect(described_class.new(rdv).generate_csv).to eq(expected_csv)
    end

    it "uses the participation's temporal status, not the RDV's" do
      rdv.participations.find_by!(user: user1).update!(status: "seen")

      expected_csv = <<~CSV
        full_name,email,status
        Alice MARTIN,alice@example.com,Rendez-vous honoré
        Bob DUPONT,bob@example.com,Rendez-vous à venir
      CSV
      expect(described_class.new(rdv).generate_csv).to eq(expected_csv)
    end
  end
end
