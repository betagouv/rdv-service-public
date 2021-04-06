describe Territory, type: :model do
  describe "Territory.with_agent" do
    subject { described_class.with_agent(agent) }

    context "agent has no territorial roles" do
      let!(:agent) { create(:agent) }

      it { is_expected.to be_empty }
    end

    context "agent has role in 2 territories" do
      let!(:agent) { create(:agent) }
      let!(:territory1) { create(:territory) }
      let!(:territory2) { create(:territory) }
      let!(:agent_territorial_role1) { create(:agent_territorial_role, territory: territory1, agent: agent) }
      let!(:agent_territorial_role2) { create(:agent_territorial_role, territory: territory2, agent: agent) }

      it { is_expected.to match_array([territory1, territory2]) }
    end
  end

  describe "#unique_departement_number validation" do
    subject { territory.valid? }

    context "no collision" do
      let(:territory) { described_class.new(name: "Oise", departement_number: "60") }

      it { is_expected.to eq true }
    end

    context "blank departement_number" do
      let!(:territory_existing) { create(:territory, departement_number: "60") }
      let(:territory) { described_class.new(name: "Oise", departement_number: "") }

      it { is_expected.to eq true }
    end

    context "colliding departement_number" do
      let!(:territory_existing) { create(:territory, departement_number: "60") }
      let(:territory) { described_class.new(name: "Oise", departement_number: "60") }

      it { is_expected.to eq false }

      it "adds errors" do
        territory.valid?
        expect(territory.errors).not_to be_empty
        expect(territory.errors[:base]).not_to be_empty
        expect(territory.errors[:base][0]).to include("agents créés dans ce département")
      end
    end

    context "update existing territory to free departement_number" do
      let!(:territory) { create(:territory, departement_number: "60") }

      before { territory.departement_number = "80" }

      it { is_expected.to eq true }
    end

    context "update existing territory to colliding departement_number" do
      let!(:territory_existing) { create(:territory, departement_number: "80") }
      let!(:territory) { create(:territory, departement_number: "60") }

      before { territory.departement_number = "80" }

      it { is_expected.to eq false }

      it "adds errors" do
        territory.valid?
        expect(territory.errors).not_to be_empty
        expect(territory.errors[:base]).not_to be_empty
        expect(territory.errors[:base][0]).to include("agents créés dans ce département")
      end
    end
  end

  describe "#fill_name_for_departements before_create" do
    subject { territory.reload.name }

    before { territory.save! }

    context "new territory without departement_number" do
      let(:territory) { described_class.new(departement_number: nil) }

      it { is_expected.to eq nil }
    end

    context "new territory with recognized departement_number" do
      let(:territory) { described_class.new(departement_number: "60") }

      it { is_expected.to eq "Oise" }
    end

    context "new territory with name overriden" do
      let(:territory) { described_class.new(name: "LA grande Oise", departement_number: "60") }

      it { is_expected.to eq "LA grande Oise" }
    end

    context "new territory with departement_number not recognized" do
      let(:territory) { described_class.new(departement_number: "600") }

      it { is_expected.to eq nil }
    end
  end
end
