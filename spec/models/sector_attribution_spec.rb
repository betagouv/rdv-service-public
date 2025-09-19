RSpec.describe SectorAttribution, type: :model do
  let!(:territory) { build_stubbed(:territory) }
  let!(:organisation) { build_stubbed(:organisation, territory:) }
  let!(:sector) { build_stubbed(:sector, territory:) }

  it "validation of presence of level" do
    expect(build(:sector_attribution, level: SectorAttribution::LEVEL_ORGANISATION)).to be_valid
    expect(build(:sector_attribution, level: nil)).not_to be_valid
  end

  describe "validation of presence of agent only if level is agent" do
    it "works" do
      agent = build_stubbed(:agent)

      expect(build(:sector_attribution, :level_organisation, organisation:, sector:, agent: nil)).to be_valid
      expect(build(:sector_attribution, :level_organisation, organisation:, sector:, agent:)).not_to be_valid

      expect(build(:sector_attribution, :level_agent, organisation:, sector:, agent:)).to be_valid
      expect(build(:sector_attribution, :level_agent, organisation:, sector:, agent: nil)).not_to be_valid
    end
  end

  describe "#organisation_is_in_sector_territory" do
    it "works" do
      legit_org = build_stubbed(:organisation, territory:)
      other_org = build_stubbed(:organisation, territory: build_stubbed(:territory))

      expect(build(:sector_attribution, sector:, organisation: legit_org)).to be_valid
      expect(build(:sector_attribution, sector:, organisation: other_org)).not_to be_valid
    end
  end
end
