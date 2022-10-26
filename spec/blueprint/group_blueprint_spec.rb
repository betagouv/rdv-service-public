# frozen_string_literal: true

RSpec.describe GroupBlueprint do
  describe "render" do
    it "contains the territory data" do
      territory = build_stubbed(:territory)
      parsed_group = JSON.parse(described_class.render(territory, root: :territory)).with_indifferent_access
      expect(parsed_group[:territory]).to match(
        {
          id: territory.id,
          label: territory.name,
          name: territory.departement_number,
        }
      )
    end
  end
end
