RSpec.describe RdvBlueprint do
  subject(:json) { JSON.parse(rendered) }

  let(:rendered) { described_class.render(rdv, { root: :rdv }) }
  let(:rdv) { build(:rdv) }

  describe "status" do
    let(:motif) { create(:motif) }
    let(:rdv) { build(:rdv, status: "revoked", motif: motif) }

    it do
      expect(json.dig("rdv", "status")).to eq "revoked"
      expect(json.dig("rdv", "motif", "motif_category", "id")).to eq MotifCategory.first.id
    end
  end

  it "shows rdv collectif fields" do
    expect(json["rdv"]).to include({
                                     "collectif" => false,
                                     "context" => nil,
                                     "created_by" => "agent",
                                     "duration_in_min" => 45,
                                     "max_participants_count" => nil,
                                     "name" => nil,
                                   })
  end

  describe "users (DEPRECATED)" do
    let(:user) { build(:user, first_name: "Jean") }
    let(:rdv) { build(:rdv, users: [user]) }

    it do
      expect(json.dig("rdv", "users").first["first_name"]).to eq "Jean"
    end
  end

  describe "participations contains user" do
    let(:user) { build(:user, first_name: "Jean") }
    let(:rdv) { build(:rdv, participations: [participation]) }
    let(:participation) { build(:participation, status: "seen", user: user) }

    it do
      expect(json.dig("rdv", "participations").first["status"]).to eq "seen"
      expect(json.dig("rdv", "participations").first["user"]["first_name"]).to eq "Jean"
    end
  end
end
