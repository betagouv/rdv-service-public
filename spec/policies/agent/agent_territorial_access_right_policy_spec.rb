RSpec.describe Agent::AgentTerritorialAccessRightPolicy do
  let(:territory) { create(:territory) }
  let(:agent_territorial_access_right) { create(:agent_territorial_access_right, territory: territory) }

  let(:policy) { described_class.new(agent, agent_territorial_access_right) }

  context "without admin access to this territory" do
    let(:agent) { create(:agent, admin_in_territories: []) }

    it "returns false" do
      expect(policy.update?).to be_falsey
    end
  end

  context "with agent admin to this territory but no access rights to change access rights" do
    let(:agent) { create(:agent, admin_in_territories: [territory]) }

    it "returns false" do
      expect(policy.update?).to be_falsey
    end
  end

  context "with access rights to manage access rights" do
    let(:agent) { create(:agent) }

    it "returns true with agent with access rights for access rights" do
      create(:agent_territorial_access_right, agent: agent, territory: territory, allow_to_manage_access_rights: true)

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
      expect(policy.update?).to be true
    end
  end

  describe "#permitted_attributes" do
    context "with no rights at all" do
      let(:agent) { create(:agent, admin_in_territories: []) }

      it "permits nothing" do
        expect(policy.permitted_attributes).to be_empty
      end
    end

    context "with allow_to_manage_access_rights only" do
      let(:agent) { create(:agent) }

      it "permits the 3 specific rights, but not territory_admin" do
        create(:agent_territorial_access_right, agent: agent, territory: territory, allow_to_manage_access_rights: true)

        expect(policy.permitted_attributes).to contain_exactly(:allow_to_manage_teams, :allow_to_manage_access_rights, :allow_to_invite_agents)
      end
    end

    context "as territory admin, able to see the target agent" do
      let(:organisation) { create(:organisation, territory: territory) }
      let(:agent) { create(:agent, admin_in_territories: [territory]) }
      let(:target_agent) { create(:agent, basic_role_in_organisations: [organisation]) }
      let(:agent_territorial_access_right) { create(:agent_territorial_access_right, agent: target_agent, territory: territory) }

      it "permits territory_admin, but not the 3 specific rights" do
        expect(policy.permitted_attributes).to contain_exactly(:territory_admin)
      end
    end
  end
end
