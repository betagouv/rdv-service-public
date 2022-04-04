# frozen_string_literal: true

describe RdvBlueprint do
  subject(:json) { JSON.parse(rendered) }

  let(:rendered) { described_class.render(rdv, { root: :rdv }) }

  describe "status" do
    let(:rdv) { build(:rdv, status: "revoked") }

    it do
      expect(json.dig("rdv", "status")).to eq "revoked"
      expect(json.dig("rdv", "motif", "category")).to eq Motif.categories.first.first
    end
  end
end
