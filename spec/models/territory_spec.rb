# frozen_string_literal: true

describe Territory, type: :model do
  it "have a valid factory" do
    expect(build(:territory)).to be_valid
  end

  describe "#organisations_agents request don't include duplicates" do
    context "when an agent is attached to 2 organisations" do
      let(:territory) { create(:territory) }
      let(:organisation1) { create(:organisation, territory: territory) }
      let(:organisation2) { create(:organisation, territory: territory) }
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation1, organisation2]) }

      it { expect(territory.organisations_agents.count).to eq(1) }
    end
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

  describe "#to_s" do
    it "returns name and departement number if exist" do
      territory = build(:territory, departement_number: "93", name: "Seine Saint-Denis")
      expect(territory.to_s).to eq("Seine Saint-Denis - 93")
    end

    it "returns name" do
      territory = build(:territory, departement_number: nil, name: "Seine Saint-Denis")
      expect(territory.to_s).to eq("Seine Saint-Denis")
    end
  end

  describe "#waiting_room_enabled?" do
    it "returns false when no notification selected" do
      territory = build(:territory, enable_waiting_room_mail_field: false, enable_waiting_room_color_field: false)
      expect(territory.waiting_room_enabled?).to eq(false)
    end

    it "returns true when mail notification selected" do
      territory = build(:territory, enable_waiting_room_mail_field: true, enable_waiting_room_color_field: false)
      expect(territory.waiting_room_enabled?).to eq(true)
    end

    it "returns true when agenda rdv color notification selected" do
      territory = build(:territory, enable_waiting_room_mail_field: false, enable_waiting_room_color_field: true)
      expect(territory.waiting_room_enabled?).to eq(true)
    end
  end
end
