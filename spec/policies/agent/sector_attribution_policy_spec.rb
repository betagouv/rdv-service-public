describe Agent::SectorAttributionPolicy, type: :policy do
  subject { described_class }

  let!(:territory) { create(:territory) }
  let(:pundit_context) { AgentContext.new(agent) }

  [:new?, :create?, :destroy?].each do |action|
    describe "##{action}" do
      let!(:agent) { create(:agent, role_in_territories: [territory]) }

      context "agent has role in territory" do
        let!(:organisation) { create(:organisation, territory: territory) }
        let!(:sector) { create(:sector, territory: territory) }
        let!(:sector_attribution) { build(:sector_attribution, sector: sector, organisation: organisation) }
        permissions(action) { it { should permit(pundit_context, sector_attribution) } }
      end

      context "agent does not have role in territory" do
        let!(:territory2) { create(:territory) }
        let!(:organisation) { create(:organisation, territory: territory2) }
        let!(:sector) { create(:sector, territory: territory2) }
        let!(:sector_attribution) { build(:sector_attribution, sector: sector, organisation: organisation) }
        permissions(action) { it { should_not permit(pundit_context, sector_attribution) } }
      end
    end
  end
end

describe Agent::SectorAttributionPolicy::Scope, type: :policy do
  describe "#resolve?" do
    subject do
      Agent::SectorAttributionPolicy::Scope.new(AgentContext.new(agent), SectorAttribution).resolve
    end

    context "misc state" do
      let!(:territory1) { create(:territory) }
      let!(:territory2) { create(:territory) }
      let!(:territory3) { create(:territory) }
      let!(:agent) { create(:agent, role_in_territories: [territory1, territory2]) }
      let!(:attribution1) do
        create(
          :sector_attribution,
          sector: create(:sector, territory: territory1),
          organisation: build(:organisation, territory: territory1)
        )
      end
      let!(:attribution1bis) do
        create(
          :sector_attribution,
          sector: create(:sector, territory: territory1),
          organisation: build(:organisation, territory: territory1)
        )
      end
      let!(:attribution2) do
        create(
          :sector_attribution,
          sector: create(:sector, territory: territory2),
          organisation: build(:organisation, territory: territory2)
        )
      end
      let!(:attribution3) do
        create(
          :sector_attribution,
          sector: create(:sector, territory: territory3),
          organisation: build(:organisation, territory: territory3)
        )
      end

      it { should include(attribution1) }
      it { should include(attribution1bis) }
      it { should include(attribution2) }
      it { should_not include(attribution3) }
    end
  end
end
