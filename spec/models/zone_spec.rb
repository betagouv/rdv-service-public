# frozen_string_literal: true

require "rails_helper"

RSpec.describe Zone, type: :model do
  let(:territory75) { build(:territory, departement_number: "75") }
  let(:sector) { build(:sector, territory: territory75) }

  describe "uniqueness" do
    context "city zone" do
      let(:zone_attributes) do
        {
          sector: sector,
          level: "city",
          city_name: "Paris XXe",
          city_code: "75120"
        }
      end

      it "allows creating a new zone" do
        zone = described_class.new(zone_attributes)
        expect(zone.valid?).to eq true
        expect(zone.errors).to be_empty
      end

      it "prevents creating a zone with existing postcode in the same sector" do
        described_class.create!(zone_attributes)
        duplicate_zone = described_class.new(
          sector: sector,
          level: "city",
          city_name: "Paris 20e",
          city_code: "75120"
        )
        expect(duplicate_zone.valid?).to eq false
        expect(duplicate_zone.errors.keys).to include(:city_code)
      end

      it "allows creating a zone with existing postcode in a different sector" do
        described_class.create!(zone_attributes)
        duplicate_zone = described_class.new(
          sector: create(:sector, territory: territory75),
          level: "city",
          city_name: "Paris 20e",
          city_code: "75120"
        )
        expect(duplicate_zone.errors.keys).to be_empty
        expect(duplicate_zone.valid?).to eq true
      end
    end
  end

  describe "incoherent departement and city code" do
    it "is invalid" do
      zone = described_class.new(
        sector: sector,
        level: "city",
        city_name: "Paris XXe",
        city_code: "62120"
      )
      expect(zone.valid?).to eq false
      expect(zone.errors.keys).to eq([:base])
    end
  end
end
