describe SuperAdmin, type: :model do
  let(:super_admin) { create(:super_admin) }

  describe "validations" do
    it "is valid with valid attributes" do
      expect(super_admin).to be_valid
    end

    it "is not valid without a first name" do
      super_admin.first_name = nil
      expect(super_admin).not_to be_valid
    end

    it "is not valid without a last name" do
      super_admin.last_name = nil
      expect(super_admin).not_to be_valid
    end
  end

  describe "#name_for_paper_trail" do
    context "when impersonated is blank" do
      it "returns the correct string" do
        expect(super_admin.name_for_paper_trail).to eq("[Admin] #{super_admin.full_name}")
      end
    end

    context "when impersonated is not blank" do
      let(:agent) { create(:agent) }

      it "returns the correct string" do
        expect(super_admin.name_for_paper_trail(impersonated: agent)).to eq("[Admin] #{super_admin.full_name} pour #{agent.full_name}")
      end
    end
  end
end
