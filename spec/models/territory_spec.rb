# frozen_string_literal: true

describe Territory, type: :model do
  it "have a valid factory" do
    expect(build(:territory)).to be_valid
  end

  describe "departement_number uniqueness validation" do
    context "no collision" do
      let(:territory) { build(:territory, name: "Oise", departement_number: "60") }

      it { expect(territory).to be_valid }
    end

    context "blank departement_number" do
      let!(:territory_existing) { create(:territory, departement_number: "60") }
      let(:territory) { build(:territory, name: "Oise", departement_number: "") }

      it { expect(territory).to be_valid }
    end

    context "colliding departement_number" do
      let!(:territory_existing) { create(:territory, departement_number: "60") }
      let(:territory) { build(:territory, name: "Oise", departement_number: "60") }

      it "adds errors" do
        expect(territory).not_to be_valid
        expect(territory.errors.details).to eq({ departement_number: [{ error: :taken, value: "60" }] })
        expect(territory.errors.full_messages.to_sentence).to include("agents créés dans ce département")
      end
    end

    context "update existing territory to free departement_number" do
      let!(:territory) { create(:territory, departement_number: "60") }

      before { territory.departement_number = "80" }

      it { expect(territory).to be_valid }
    end

    context "update existing territory to colliding departement_number" do
      let!(:territory_existing) { create(:territory, departement_number: "80") }
      let!(:territory) { create(:territory, departement_number: "60") }

      before { territory.departement_number = "80" }

      it "adds errors" do
        expect(territory).not_to be_valid
        expect(territory.errors.details).to eq({ departement_number: [{ error: :taken, value: "80" }] })
        expect(territory.errors.full_messages.to_sentence).to include("agents créés dans ce département")
      end
    end
  end

  describe "#fill_name_for_departements before_create" do
    subject { territory.reload.name }

    before { territory.save! }

    context "new territory without departement_number" do
      let(:territory) { build(:territory, name: nil, departement_number: "") }

      it { is_expected.to eq nil }
    end

    context "new territory with recognized departement_number" do
      let(:territory) { build(:territory, name: nil, departement_number: "60") }

      it { is_expected.to eq "Oise" }
    end

    context "new territory with name overridden" do
      let(:territory) { build(:territory, name: "LA grande Oise", departement_number: "60") }

      it { is_expected.to eq "LA grande Oise" }
    end

    context "new territory with departement_number not recognized" do
      let(:territory) { build(:territory, name: "", departement_number: "600") }

      it { is_expected.to eq nil }
    end
  end

  describe "#full_name" do
    it "returns only territory.name without departement" do
      territory = build(:territory, departement_number: nil, name: "Paris")
      expect(territory.full_name).to eq("Paris")
    end

    it "returns territory.departement_number - territory.name with departement" do
      territory = build(:territory, departement_number: "75", name: "Paris")
      expect(territory.full_name).to eq("75 - Paris")
    end
  end
end
