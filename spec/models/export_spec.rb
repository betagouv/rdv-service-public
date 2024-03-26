RSpec.describe Export do
  describe "#organisations" do
    it "returns a scope of linked orgs" do
      orgs = create_list(:organisation, 2)
      export = create(:export, organisation_ids: [orgs[1].id, orgs[0].id])
      expect(export.organisations).to match_array(orgs)
    end
  end

  describe "#expires_at" do
    it "is set upon build" do
      export = build(:export)
      expect(export.expires_at).to be_within(1.second).of(6.hours.from_now)
    end
  end

  describe "#available" do
    it "returns true when computed but not expired" do
      export = build(:export)
      expect(export).not_to be_available

      export.store_file("dummy_data")
      expect(export).to be_available

      export.expires_at = 2.seconds.ago
      expect(export).not_to be_available
    end
  end

  describe "#to_s" do
    context "when RDV is of type RDV_EXPORT" do
      let(:export) { build(:export, created_at: Time.zone.parse("2024-02-29 16:30:12"), export_type: described_class::RDV_EXPORT) }

      it "indicates type and datetime" do
        expect(export.to_s).to eq("Export de RDV du 29/02/2024 à 16:30")
      end
    end

    context "when RDV is of type PARTICIPATIONS_EXPORT" do
      let(:export) { build(:export, created_at: Time.zone.parse("2024-02-29 16:30:12"), export_type: described_class::PARTICIPATIONS_EXPORT) }

      it "indicates type and datetime" do
        expect(export.to_s).to eq("Export de RDV par usager du 29/02/2024 à 16:30")
      end
    end
  end

  describe "#store_file and #load_file" do
    it "works" do
      export = create(:export)

      expect { export.load_file }.to raise_error(Export::FileNotFoundError)
      expect(export.computed_at).to be_nil

      export.store_file("dummy_data")
      expect(export.load_file).to eq("dummy_data")
      expect(export.computed_at).to be_within(1.second).of(Time.zone.now)
    end
  end
end
