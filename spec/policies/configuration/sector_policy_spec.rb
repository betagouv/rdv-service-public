RSpec.describe Configuration::SectorPolicy, type: :policy do
  subject { described_class }

  context "agent does not have any territorial role" do
    let(:territory) { create(:territory) }
    let(:sector) { create(:sector, territory:) }
    let(:agent) { create(:agent) }
    let(:pundit_context) { AgentTerritorialContext.new(agent, territory) }

    it_behaves_like "not permit actions",
                    :sector,
                    :new?,
                    :create?,
                    :show?,
                    :edit?,
                    :update?,
                    :destroy?
  end

  context "agent has territorial role in sector territory" do
    let(:territory) { create(:territory) }
    let(:sector) { create(:sector, territory:) }
    let(:agent) { create(:agent, role_in_territories: [territory]) }
    let(:pundit_context) { AgentTerritorialContext.new(agent, territory) }

    it_behaves_like "permit actions",
                    :sector,
                    :new?,
                    :create?,
                    :show?,
                    :edit?,
                    :update?,
                    :destroy?
  end

  context "agent has territorial role in other territory" do
    let(:territory_sector) { create(:territory) }
    let(:territory_agent) { create(:territory) }
    let(:sector) { create(:sector, territory: territory_sector) }
    let(:agent) { create(:agent, role_in_territories: [territory_agent]) }

    context "context uses agent’s territory" do
      let(:pundit_context) { AgentTerritorialContext.new(agent, territory_agent) }

      it_behaves_like "not permit actions",
                      :sector,
                      :new?,
                      :create?,
                      :show?,
                      :edit?,
                      :update?,
                      :destroy?
    end

    context "context uses sector's territory" do
      let(:pundit_context) { AgentTerritorialContext.new(agent, territory_sector) }

      it_behaves_like "not permit actions",
                      :sector,
                      :new?,
                      :create?,
                      :show?,
                      :edit?,
                      :update?,
                      :destroy?
    end
  end

  describe Configuration::SectorPolicy::Scope, type: :policy do
    let!(:territory_paris) { create(:territory) }
    let!(:sector_montparnasse) { create(:sector, territory: territory_paris) }
    let!(:sector_vautgirard) { create(:sector, territory: territory_paris) }

    let!(:territory_marseille) { create(:territory) }
    let!(:sector_timone) { create(:sector, territory: territory_marseille) }
    let!(:sector_baille) { create(:sector, territory: territory_marseille) }

    let!(:territory_lyon) { create(:territory) }
    let!(:sector_perrache) { create(:sector, territory: territory_lyon) }
    let!(:sector_partdieu) { create(:sector, territory: territory_lyon) }

    context "agent has territorial roles in Paris and Marseille" do
      let(:agent) { create(:agent, role_in_territories: [territory_paris, territory_marseille]) }

      context "scope all sectors using Paris as context territory" do
        subject { described_class.new(AgentTerritorialContext.new(agent, territory_paris), Sector.all).resolve }

        it { is_expected.to contain_exactly(sector_montparnasse, sector_vautgirard, sector_timone, sector_baille) }
      end

      context "scope Paris sectors using Paris as context territory" do
        subject do
          described_class.new(
            AgentTerritorialContext.new(agent, territory_paris),
            Sector.where(territory_id: territory_paris.id)
          ).resolve
        end

        it { is_expected.to contain_exactly(sector_montparnasse, sector_vautgirard) }
      end

      context "scope Marseille sectors using Paris as context territory" do
        subject do
          described_class.new(
            AgentTerritorialContext.new(agent, territory_paris),
            Sector.where(territory_id: territory_marseille.id)
          ).resolve
        end

        it { is_expected.to contain_exactly(sector_timone, sector_baille) }
      end

      context "scope Lyon sectors using Paris as context territory" do
        subject do
          described_class.new(
            AgentTerritorialContext.new(agent, territory_paris),
            Sector.where(territory_id: territory_lyon.id)
          ).resolve
        end

        it { is_expected.to be_empty }
      end
    end

    context "agent has single territorial role in Paris" do
      let(:agent) { create(:agent, role_in_territories: [territory_paris]) }

      context "scope all sectors using Paris as context territory" do
        subject { described_class.new(AgentTerritorialContext.new(agent, territory_paris), Sector.all).resolve }

        it { is_expected.to contain_exactly(sector_montparnasse, sector_vautgirard) }
      end

      context "scope Paris sectors using Paris as context territory" do
        subject do
          described_class.new(
            AgentTerritorialContext.new(agent, territory_paris),
            Sector.where(territory_id: territory_paris.id)
          ).resolve
        end

        it { is_expected.to contain_exactly(sector_montparnasse, sector_vautgirard) }
      end

      context "scope Marseille sectors using Paris as context territory" do
        subject do
          described_class.new(
            AgentTerritorialContext.new(agent, territory_paris),
            Sector.where(territory_id: territory_marseille.id)
          ).resolve
        end

        it { is_expected.to be_empty }
      end
    end

    context "agent has no territorial roles at all" do
      let(:agent) { create(:agent, role_in_territories: []) }

      context "scope all sectors using Paris as context territory" do
        subject { described_class.new(AgentTerritorialContext.new(agent, territory_paris), Sector.all).resolve }

        it { is_expected.to be_empty }
      end

      context "scope Paris sectors using Paris as context territory" do
        subject do
          described_class.new(
            AgentTerritorialContext.new(agent, territory_paris),
            Sector.where(territory_id: territory_paris.id)
          ).resolve
        end

        it { is_expected.to be_empty }
      end
    end
  end
end
