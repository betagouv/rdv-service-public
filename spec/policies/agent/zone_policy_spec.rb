describe Agent::ZonePolicy, type: :policy do
  subject { described_class }

  let!(:territory) { create(:territory) }
  let(:pundit_context) { AgentContext.new(agent) }

  [:new?, :create?, :destroy?].each do |action|
    describe "##{action}" do
      let!(:agent) { create(:agent, role_in_territories: [territory]) }

      context "agent has role in territory" do
        let!(:sector) { create(:sector, territory: territory) }
        let!(:zone) { build(:zone, sector: sector) }
        permissions(action) { it { should permit(pundit_context, zone) } }
      end

      context "agent does not have role in territory" do
        let!(:territory2) { create(:territory) }
        let!(:sector) { create(:sector, territory: territory2) }
        let!(:zone) { build(:zone, sector: sector) }
        permissions(action) { it { should_not permit(pundit_context, zone) } }
      end
    end
  end
end

describe Agent::ZonePolicy::Scope, type: :policy do
  describe "#resolve?" do
    subject do
      Agent::ZonePolicy::Scope.new(AgentContext.new(agent), Zone).resolve
    end

    context "misc state" do
      let!(:territory70) { create(:territory, departement_number: "70") }
      let!(:territory72) { create(:territory, departement_number: "72") }
      let!(:territory73) { create(:territory, departement_number: "73") }
      let!(:agent) { create(:agent, role_in_territories: [territory70, territory72]) }
      let!(:zone70) { create(:zone, city_code: "70000", sector: create(:sector, territory: territory70)) }
      let!(:zone70bis) { create(:zone, city_code: "70100", sector: create(:sector, territory: territory70)) }
      let!(:zone72) { create(:zone, city_code: "72000", sector: create(:sector, territory: territory72)) }
      let!(:zone73) { create(:zone, city_code: "73000", sector: create(:sector, territory: territory73)) }

      it { should include(zone70) }
      it { should include(zone70bis) }
      it { should include(zone72) }
      it { should_not include(zone73) }
    end
  end
end
