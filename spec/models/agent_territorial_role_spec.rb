describe AgentTerritorialRole, type: :model do
  describe "#territory_has_at_least_one_role_before_destroy" do
    context "there is another agent with territory role" do
      let!(:territory) { create(:territory) }
      let!(:role1) { create(:agent_territorial_role, territory: territory) }
      let!(:role2) { create(:agent_territorial_role, territory: territory) }

      it "allows destroying one role" do
        role1.destroy
        expect(territory.roles.count).to eq 1
      end
    end

    context "there are no other agents with territory role" do
      let!(:territory) { create(:territory) }
      let!(:role1) { create(:agent_territorial_role, territory: territory) }

      it "does not allow destroying it" do
        role1.destroy
        expect(territory.roles.count).to eq 1
        expect(role1.errors).to be_present
      end
    end
  end
end
