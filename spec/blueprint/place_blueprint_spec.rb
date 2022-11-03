# frozen_string_literal: true

RSpec.describe PlaceBlueprint do
  describe "render" do
    it "contains the place data" do
      lieu = build_stubbed(:lieu)
      parsed_place = JSON.parse(described_class.render(lieu, root: :place)).with_indifferent_access
      expect(parsed_place[:place]).to match(
        {
          id: lieu.id,
          organization_id: lieu.organisation_id,
          label: lieu.name,
          address: lieu.address,
          latitude: lieu.latitude,
          longitude: lieu.longitude,
          phone_number: lieu.phone_number,
        }
      )
    end
  end
end
