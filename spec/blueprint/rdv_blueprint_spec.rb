# frozen_string_literal: true

describe RdvBlueprint do
  subject(:json) { JSON.parse(rendered) }

  let(:rendered) { described_class.render(rdv, { root: :rdv }.merge(options)) }

  describe "compatibility option rdv_status_compatibility1" do
    let(:rdv) { build(:rdv, status: "revoked") }

    context "with no option" do
      let(:options) { {} }

      it "passes option" do
        expect(json.dig("rdv", "status")).to eq "revoked"
      end
    end

    context "with compatibility option" do
      let(:options) { { api_options: ["rdv_status_compatibility1"] } }

      it "passes option" do
        expect(json.dig("rdv", "status")).to eq "excused"
      end
    end
  end
end
