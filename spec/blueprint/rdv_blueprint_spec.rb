# frozen_string_literal: true

describe RdvBlueprint do
  subject(:json) { JSON.parse(rendered) }

  let(:rendered) { described_class.render(rdv, { root: :rdv }) }
  let(:rdv) { build(:rdv) }

  describe "status" do
    let(:rdv) { build(:rdv, status: "revoked") }

    it do
      expect(json.dig("rdv", "status")).to eq "revoked"
      expect(json.dig("rdv", "motif", "category")).to eq Motif.categories.first.first
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
end
