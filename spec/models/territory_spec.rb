RSpec.describe Territory, type: :model do
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

  describe "#fill_name_for_departements before_create" do
    subject { territory.reload.name }

    before { territory.save! }

    context "new territory without departement_number" do
      let(:territory) { build(:territory, name: nil, departement_number: "") }

      it { is_expected.to be_nil }
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

      it { is_expected.to be_nil }
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
      expect(territory.waiting_room_enabled?).to be(false)
    end

    it "returns true when mail notification selected" do
      territory = build(:territory, enable_waiting_room_mail_field: true, enable_waiting_room_color_field: false)
      expect(territory.waiting_room_enabled?).to be(true)
    end

    it "returns true when agenda rdv color notification selected" do
      territory = build(:territory, enable_waiting_room_mail_field: false, enable_waiting_room_color_field: true)
      expect(territory.waiting_room_enabled?).to be(true)
    end
  end

  describe "special names" do
    let(:mairies_territory) do
      create(:territory, :mairies)
    end

    it "doesn't allow changing the name of a territory with a special meaning" do
      expect(mairies_territory.update(name: "new name")).to be_falsey
      expect(mairies_territory.reload.name).to eq Territory::MAIRIES_NAME
    end

    it "doesn't allow changing to the name of a territory with a special meaning" do
      normal_territory = create(:territory, name: "Ardennes")

      expect(normal_territory.update(name: Territory::MAIRIES_NAME)).to be_falsey
      expect(normal_territory.reload.name).to eq "Ardennes"
    end
  end
end
