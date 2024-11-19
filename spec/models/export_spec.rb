RSpec.describe Export do
  describe ".for_organisation" do
    let!(:export_for_org_1) { create(:export, organisation_ids: [1]) }
    let!(:export_for_org_1_and_2) { create(:export, organisation_ids: [1, 2]) }
    let!(:export_for_org_2) { create(:export, organisation_ids: [2]) }

    it "returns the exports that include data from the given organisation" do
      expect(described_class.for_organisation(1)).to contain_exactly(export_for_org_1, export_for_org_1_and_2)
    end
  end

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

  describe "#destroy" do
    it "cleans up the data in redis" do
      export = create(:export)
      export.store_file("my content")

      expect(export.load_file).to eq("my content")
      export.destroy
      expect { export.load_file }.to raise_error(RedisFileStorable::FileNotFoundError)
    end
  end
end
