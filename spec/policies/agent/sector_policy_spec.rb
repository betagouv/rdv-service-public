describe Agent::SectorPolicy, type: :policy do
  subject { described_class }

  let!(:territory) { create(:territory) }
  let(:pundit_context) { AgentContext.new(agent) }

  %i[new? create? show? edit? update? destroy?].each do |action|
    describe "##{action}" do
      let!(:agent) { create(:agent, role_in_territories: [territory]) }

      context "agent has role in territory" do
        let!(:sector) { create(:sector, territory: territory) }

        permissions(action) { it { is_expected.to permit(pundit_context, sector) } }
      end

      context "agent does not have role in territory" do
        let!(:territory2) { create(:territory) }
        let!(:sector) { create(:sector, territory: territory2) }

        permissions(action) { it { is_expected.not_to permit(pundit_context, sector) } }
      end
    end
  end
end

describe Agent::SectorPolicy::Scope, type: :policy do
  describe "#resolve?" do
    subject do
      described_class.new(AgentContext.new(agent), Sector).resolve
    end

    context "misc state" do
      let!(:territory1) { create(:territory) }
      let!(:territory2) { create(:territory) }
      let!(:territory3) { create(:territory) }
      let!(:agent) { create(:agent, role_in_territories: [territory1, territory2]) }
      let!(:sector1) { create(:sector, territory: territory1) }
      let!(:sector1bis) { create(:sector, territory: territory1) }
      let!(:sector2) { create(:sector, territory: territory2) }
      let!(:sector3) { create(:sector, territory: territory3) }

      it { is_expected.to include(sector1) }
      it { is_expected.to include(sector1bis) }
      it { is_expected.to include(sector2) }
      it { is_expected.not_to include(sector3) }
    end
  end
end
