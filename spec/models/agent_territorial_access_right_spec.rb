RSpec.describe AgentTerritorialAccessRight, type: :model do
  describe "at least one territory_admin admin per territory" do
    context "there is another agent with territory_admin" do
      let!(:territory) { create(:territory) }
      let!(:access_right1) { create(:agent_territorial_access_right, :territory_admin, territory: territory) }
      let!(:access_right2) { create(:agent_territorial_access_right, :territory_admin, territory: territory) }

      it "allows destroying one" do
        access_right1.destroy
        expect(territory.agent_territorial_access_rights.where(territory_admin: true).count).to eq 1
      end

      it "allows unsetting territory_admin on one" do
        access_right1.update(territory_admin: false)
        expect(access_right1.reload.territory_admin?).to be false
        expect(territory.agent_territorial_access_rights.where(territory_admin: true).count).to eq 1
      end
    end

    context "there are no other agents with territory_admin" do
      let!(:territory) { create(:territory) }
      let!(:access_right1) { create(:agent_territorial_access_right, :territory_admin, territory: territory) }

      it "does not allow destroying it" do
        access_right1.destroy
        expect(territory.agent_territorial_access_rights.where(territory_admin: true).count).to eq 1
        expect(access_right1.errors).to be_present
      end

      it "does not allow unsetting territory_admin on it" do
        access_right1.update(territory_admin: false)
        expect(access_right1.reload.territory_admin?).to be true
        expect(access_right1.errors).to be_present
      end
    end
  end
end
