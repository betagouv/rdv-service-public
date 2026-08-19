RSpec.describe Agent::AgentTerritorialAccessRightPolicy do
  let(:territory) { create(:territory) }
  let(:agent_territorial_access_right) { create(:agent_territorial_access_right, territory: territory) }

  let(:policy) { described_class.new(agent, agent_territorial_access_right) }

  context "without admin access to this territory" do
    let(:agent) { create(:agent, admin_in_territories: []) }

    it "returns false" do
      expect(policy.edit?).to be_falsey
      expect(policy.update?).to be_falsey
    end
  end

  context "with agent admin to this territory but no access rights to change access rights" do
    let(:agent) { create(:agent, admin_in_territories: [territory]) }

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

  context "current_agent is territorial admin and can see the target agent" do
    let(:organisation) { create(:organisation, territory: territory) }
    let(:agent) { create(:agent, admin_in_territories: [territory]) }
    let(:target_agent) { create(:agent, basic_role_in_organisations: [organisation]) }
    let(:agent_territorial_access_right) { create(:agent_territorial_access_right, agent: target_agent, territory: territory) }

    it "allows editing territory_admin, but not the specific access rights" do
      expect(policy.edit_territory_admin?).to be true
      expect(policy.allow_to_manage_access_rights?).to be false
      expect(policy.edit?).to be true
      expect(policy.update?).to be true
    end
  end
end
