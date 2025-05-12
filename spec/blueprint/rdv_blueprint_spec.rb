RSpec.describe RdvBlueprint do
  subject(:json) { JSON.parse(rendered) }

  let(:rendered) { described_class.render(rdv, { root: :rdv }) }
  let(:rdv) { create(:rdv) }

  describe "status" do
    let(:motif) { create(:motif) }
    let(:rdv) { create(:rdv, status: "revoked", motif: motif, organisation: motif.organisation) }

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
    let(:rdv) { create(:rdv, users: [user]) }

    it do
      expect(json.dig("rdv", "users").first["first_name"]).to eq "Jean"
    end
  end

  describe "participations contains user" do
    let(:user) { create(:user, first_name: "Jean") }
    let(:rdv) { create(:rdv, participations: [participation]) }
    let(:participation) { create(:participation, user: user) }

    before { participation.update(status: "seen") } # On fait cette modification après les créations pour éviter qu'elle soit override par les callbacks

    it do
      expect(json.dig("rdv", "participations").first["status"]).to eq "seen"
      expect(json.dig("rdv", "participations").first["user"]["first_name"]).to eq "Jean"
    end
  end

  describe "url_for_agents" do
    let(:rdv) { create(:rdv, organisation: organisation) }
    let(:organisation) { create(:organisation) }

    it "allows api clients to display a direct link to the rdv for the agent" do
      expect(json.dig("rdv", "url_for_agents")).to eq "http://www.rdv-solidarites-test.localhost/admin/organisations/#{organisation.id}/rdvs/#{rdv.id}"
    end
  end
end
