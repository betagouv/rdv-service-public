RSpec.describe AgentTerritorialAccessRight, type: :model do
  describe "at least one full_rights admin per territory" do
    context "there is another agent with full_rights" do
      let!(:territory) { create(:territory) }
      let!(:access_right1) { create(:agent_territorial_access_right, :full_rights, territory: territory) }
      let!(:access_right2) { create(:agent_territorial_access_right, :full_rights, territory: territory) }

      it "allows destroying one" do
        access_right1.destroy
        expect(territory.agent_territorial_access_rights.where(full_rights: true).count).to eq 1
      end

      it "allows unsetting full_rights on one" do
        access_right1.update(full_rights: false)
        expect(access_right1.reload.full_rights?).to be false
        expect(territory.agent_territorial_access_rights.where(full_rights: true).count).to eq 1
      end
    end

    context "there are no other agents with full_rights" do
      let!(:territory) { create(:territory) }
      let!(:access_right1) { create(:agent_territorial_access_right, :full_rights, territory: territory) }

      it "does not allow destroying it" do
        access_right1.destroy
        expect(territory.agent_territorial_access_rights.where(full_rights: true).count).to eq 1
        expect(access_right1.errors).to be_present
      end

      it "does not allow unsetting full_rights on it" do
        access_right1.update(full_rights: false)
        expect(access_right1.reload.full_rights?).to be true
        expect(access_right1.errors).to be_present
      end
    end
  end
end
