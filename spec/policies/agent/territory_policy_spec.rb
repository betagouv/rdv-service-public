describe Agent::TerritoryPolicy, type: :policy do
  subject { described_class }

  let!(:territory) { create(:territory) }
  let(:pundit_context) { AgentContext.new(agent) }

  describe "#show?" do
    let!(:agent) { create(:agent, role_in_territories: [territory]) }

    context "agent has role in territory" do
      permissions(:show?) { it { should permit(pundit_context, territory) } }
    end

    context "agent does not have role in territory" do
      permissions(:show?) { it { should_not permit(pundit_context, create(:territory)) } }
    end
  end
end

describe Agent::TerritoryPolicy::Scope, type: :policy do
  describe "#resolve?" do
    subject do
      Agent::TerritoryPolicy::Scope.new(AgentContext.new(agent), Territory).resolve
    end

    context "misc state" do
      let!(:territory1) { create(:territory) }
      let!(:territory2) { create(:territory) }
      let!(:territory3) { create(:territory) }
      let!(:agent) { create(:agent, role_in_territories: [territory1, territory2]) }

      it { should include(territory1) }
      it { should include(territory2) }
      it { should_not include(territory3) }
    end
  end
end
