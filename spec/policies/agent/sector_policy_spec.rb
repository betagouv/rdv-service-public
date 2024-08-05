RSpec.describe Agent::SectorPolicy do
  subject { described_class }

  let(:pundit_context) { agent }

  context "agent does not have any territorial role" do
    let(:territory) { create(:territory) }
    let(:sector) { create(:sector, territory:) }
    let(:agent) { create(:agent) }

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

    it_behaves_like "not permit actions", :sector,
                    :new?,
                    :create?,
                    :show?,
                    :edit?,
                    :update?,
                    :destroy?
  end

  describe Agent::SectorPolicy::Scope do
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

      context "scope Paris sectors" do
        subject do
          described_class.new(agent, territory_paris.sectors).resolve
        end

        it { is_expected.to contain_exactly(sector_montparnasse, sector_vautgirard) }
      end
    end

    context "agent has no territorial roles at all" do
      let(:agent) { create(:agent, role_in_territories: []) }

      context "scope all sectors using Paris as context territory" do
        subject { described_class.new(agent, territory_paris.sectors).resolve }

        it { is_expected.to be_empty }
      end
    end
  end
end
