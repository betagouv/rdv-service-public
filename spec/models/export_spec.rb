RSpec.describe Export do
  describe "#expires_at" do
    it "is set upon creation" do
      export = build(:export)
      expect { export.save! }.to change(export, :expires_at).from(nil).to(be_within(1.second).of(6.hours.from_now))
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
end
