RSpec.describe Configuration::ZonePolicy, type: :policy do
  subject { described_class }

  context "agent does not have any territorial role" do
    let(:territory) { create(:territory) }
    let(:sector) { create(:sector, territory:) }
    let(:zone) { create(:zone, sector:) }
    let(:agent) { create(:agent) }
    let(:pundit_context) { AgentTerritorialContext.new(agent, territory) }

    it_behaves_like "not permit actions",
                    :zone,
                    :new?,
                    :create?,
                    :destroy?
  end

  context "agent has territorial role in zone territory" do
    let(:territory) { create(:territory) }
    let(:sector) { create(:sector, territory:) }
    let(:zone) { create(:zone, sector:) }
    let(:agent) { create(:agent, role_in_territories: [territory]) }
    let(:pundit_context) { AgentTerritorialContext.new(agent, territory) }

    it_behaves_like "permit actions",
                    :zone,
                    :new?,
                    :create?,
                    :destroy?
  end

  context "agent has territorial role in other territory" do
    let(:territory_zone) { create(:territory) }
    let(:territory_agent) { create(:territory) }
    let(:sector) { create(:sector, territory: territory_zone) }
    let(:zone) { create(:zone, sector:) }
    let(:agent) { create(:agent, role_in_territories: [territory_agent]) }

    context "context uses agent’s territory" do
      let(:pundit_context) { AgentTerritorialContext.new(agent, territory_agent) }

      it_behaves_like "not permit actions",
                      :zone,
                      :new?,
                      :create?,
                      :destroy?
    end

    context "context uses zone's territory" do
      let(:pundit_context) { AgentTerritorialContext.new(agent, territory_zone) }

      it_behaves_like "not permit actions",
                      :zone,
                      :new?,
                      :create?,
                      :destroy?
    end
  end

  describe Configuration::ZonePolicy::Scope, type: :policy do
    let!(:territory_paris) { create(:territory) }
    let!(:sector_montparnasse) { create(:sector, territory: territory_paris) }
    let!(:zone_montparnasse) { create(:zone, city_name: "Paris", sector: sector_montparnasse) }
    let!(:sector_vautgirard) { create(:sector, territory: territory_paris) }
    let!(:zone_vaugirard) { create(:zone, city_name: "Paris", sector: sector_vautgirard) }

    let!(:territory_marseille) { create(:territory) }
    let!(:sector_timone) { create(:sector, territory: territory_marseille) }
    let!(:zone_timone) { create(:zone, city_name: "Marseille", sector: sector_timone) }
    let!(:sector_baille) { create(:sector, territory: territory_marseille) }
    let!(:zone_baille) { create(:zone, city_name: "Marseille", sector: sector_baille) }

    let!(:territory_lyon) { create(:territory) }
    let!(:sector_perrache) { create(:sector, territory: territory_lyon) }
    let!(:zone_perrache) { create(:zone, city_name: "Lyon", sector: sector_perrache) }
    let!(:sector_partdieu) { create(:sector, territory: territory_lyon) }
    let!(:zone_partdieu) { create(:zone, city_name: "Lyon", sector: sector_partdieu) }

    context "agent has territorial roles in Paris and Marseille" do
      let(:agent) { create(:agent, role_in_territories: [territory_paris, territory_marseille]) }

      context "scope all zones using Paris as context territory" do
        subject { described_class.new(AgentTerritorialContext.new(agent, territory_paris), Zone.all).resolve }

        it { is_expected.to contain_exactly(zone_montparnasse, zone_vaugirard, zone_timone, zone_baille) }
      end

      context "scope Paris zones using Paris as context territory" do
        subject do
          described_class.new(
            AgentTerritorialContext.new(agent, territory_paris),
            Zone.joins(:sector).where(sectors: { territory_id: territory_paris.id })
          ).resolve
        end

        it { is_expected.to contain_exactly(zone_montparnasse, zone_vaugirard) }
      end

      context "scope Marseille zones using Paris as context territory" do
        subject do
          described_class.new(
            AgentTerritorialContext.new(agent, territory_paris),
            Zone.joins(:sector).where(sectors: { territory_id: territory_marseille.id })
          ).resolve
        end

        it { is_expected.to contain_exactly(zone_timone, zone_baille) }
      end

      context "scope Lyon zones using Paris as context territory" do
        subject do
          described_class.new(
            AgentTerritorialContext.new(agent, territory_paris),
            Zone.joins(:sector).where(sectors: { territory_id: territory_lyon.id })
          ).resolve
        end

        it { is_expected.to be_empty }
      end
    end

    context "agent has single territorial role in Paris" do
      let(:agent) { create(:agent, role_in_territories: [territory_paris]) }

      context "scope all zones using Paris as context territory" do
        subject { described_class.new(AgentTerritorialContext.new(agent, territory_paris), Zone.all).resolve }

        it { is_expected.to contain_exactly(zone_montparnasse, zone_vaugirard) }
      end

      context "scope Paris zones using Paris as context territory" do
        subject do
          described_class.new(
            AgentTerritorialContext.new(agent, territory_paris),
            Zone.joins(:sector).where(sectors: { territory_id: territory_paris.id })
          ).resolve
        end

        it { is_expected.to contain_exactly(zone_montparnasse, zone_vaugirard) }
      end

      context "scope Marseille zones using Paris as context territory" do
        subject do
          described_class.new(
            AgentTerritorialContext.new(agent, territory_paris),
            Zone.joins(:sector).where(sectors: { territory_id: territory_marseille.id })
          ).resolve
        end

        it { is_expected.to be_empty }
      end
    end

    context "agent has no territorial roles at all" do
      let(:agent) { create(:agent, role_in_territories: []) }

      context "scope all zones using Paris as context territory" do
        subject { described_class.new(AgentTerritorialContext.new(agent, territory_paris), Zone.all).resolve }

        it { is_expected.to be_empty }
      end

      context "scope Paris zones using Paris as context territory" do
        subject do
          described_class.new(
            AgentTerritorialContext.new(agent, territory_paris),
            Zone.joins(:sector).where(sectors: { territory_id: territory_paris.id })
          ).resolve
        end

        it { is_expected.to be_empty }
      end
    end
  end
end
