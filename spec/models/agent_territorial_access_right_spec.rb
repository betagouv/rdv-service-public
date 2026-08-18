RSpec.describe AgentTerritorialAccessRight, type: :model do
  describe "validations" do
    it "is valid with full_rights and no specific right" do
      access_right = build(:agent_territorial_access_right, full_rights: true)
      expect(access_right).to be_valid
    end

    it "is invalid with full_rights and a specific right" do
      access_right = build(:agent_territorial_access_right, full_rights: true, allow_to_manage_teams: true)
      expect(access_right).not_to be_valid
      expect(access_right.errors[:full_rights]).to be_present
    end
  end

  describe "at least one full_rights admin per territory" do
    context "there is another agent with full_rights" do
      let!(:territory) { create(:territory) }
      let!(:access_right1) { create(:agent_territorial_access_right, :full_rights, territory: territory) }
      let!(:access_right2) { create(:agent_territorial_access_right, :full_rights, territory: territory) }

      it "allows destroying one" do
        access_right1.destroy
        expect(territory.roles.count).to eq 1
      end

      it "allows unsetting full_rights on one" do
        access_right1.update(full_rights: false)
        expect(access_right1.reload.full_rights?).to be false
        expect(territory.roles.count).to eq 1
      end
    end

    context "there are no other agents with full_rights" do
      let!(:territory) { create(:territory) }
      let!(:access_right1) { create(:agent_territorial_access_right, :full_rights, territory: territory) }

      it "does not allow destroying it" do
        access_right1.destroy
        expect(territory.roles.count).to eq 1
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
