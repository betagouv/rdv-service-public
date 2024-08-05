# rubocop:disable RSpec/PredicateMatcher
RSpec.describe Agent::AgentTerritorialAccessRightPolicy do
  let(:territory) { create(:territory) }
  let(:agent_territorial_access_right) { create(:agent_territorial_access_right, territory: territory) }

  let(:policy) { described_class.new(agent, agent_territorial_access_right) }

  context "without admin access to this territory" do
    let(:agent) { create(:agent, role_in_territories: []) }

    it "returns false" do
      expect(policy.edit?).to be_falsey
      expect(policy.update?).to be_falsey
    end
  end

  context "with agent admin to this territory but no access rights to change access rights" do
    let(:agent) { create(:agent, role_in_territories: [territory]) }

    it "returns false" do
      expect(policy.edit?).to be_falsey
      expect(policy.update?).to be_falsey
    end
  end

  context "with access rights to manage access rights" do
    let(:agent) { create(:agent) }

    it "returns true with agent with access rights for access rights" do
      create(:agent_territorial_access_right, agent: agent, territory: territory, allow_to_manage_access_rights: true)

      expect(policy.edit?).to be true
      expect(policy.update?).to be true
    end
  end
end
# rubocop:enable RSpec/PredicateMatcher
