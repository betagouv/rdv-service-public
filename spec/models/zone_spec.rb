require "rails_helper"

RSpec.describe Zone, type: :model do
  let(:sector) { build(:sector, departement: "75") }

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

      it "should allow creating a new zone" do
        zone = Zone.new(zone_attributes)
        expect(zone.valid?).to eq true
        expect(zone.errors).to be_empty
      end

      it "should prevent creating a zone with existing postcode in the same sector" do
        Zone.create!(zone_attributes)
        duplicate_zone = Zone.new(
          sector: sector,
          level: "city",
          city_name: "Paris 20e",
          city_code: "75120"
        )
        expect(duplicate_zone.valid?).to eq false
        expect(duplicate_zone.errors.keys).to include(:city_code)
      end

      it "should allow creating a zone with existing postcode in a different sector" do
        Zone.create!(zone_attributes)
        duplicate_zone = Zone.new(
          sector: create(:sector, departement: "75"),
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
    it "should be invalid" do
      zone = Zone.new(
        sector: sector,
        level: "city",
        city_name: "Paris XXe",
        city_code: "62120"
      )
      expect(zone.valid?).to eq false
      expect(zone.errors.keys).to eq([:city_code])
    end
  end
end
