require 'rails_helper'

RSpec.describe Zone, type: :model do
  let(:organisation) { build(:organisation, departement: '75') }

  describe 'uniqueness' do
    context 'city zone' do
      let(:zone_attributes) do
        {
          organisation: organisation,
          level: 'city',
          city_name: 'Paris XXe',
          city_code: '75120'
        }
      end

      it 'should allow creating a new zone' do
        zone = Zone.new(zone_attributes)
        expect(zone.valid?).to eq true
        expect(zone.errors).to be_empty
      end

      it 'should prevent creating a zone with existing postcode' do
        Zone.create!(zone_attributes)
        duplicate_zone = Zone.new(
          organisation: build(:organisation),
          level: 'city',
          city_name: 'Paris 20e',
          city_code: '75120'
        )
        expect(duplicate_zone.valid?).to eq false
        expect(duplicate_zone.errors.keys).to include(:city_code)
      end
    end
  end

  describe 'incoherent departement and city code' do
    it 'should be invalid' do
      zone = Zone.new(
        organisation: build(:organisation, departement: '75'),
        level: 'city',
        city_name: 'Paris XXe',
        city_code: '62120'
      )
      expect(zone.valid?).to eq false
      expect(zone.errors.keys).to eq([:city_code])
    end
  end
end
