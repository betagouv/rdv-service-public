RSpec.describe MotifsComparisonPresenter do
  describe described_class::Pair do
    describe "#differences" do
      it "provides a hash with before and after versions" do
        motif_a = build_stubbed(:motif, default_duration_in_min: 30)
        motif_b = motif_a.dup
        motif_b.default_duration_in_min = 45

        expect(described_class.new(motif_a, motif_b).differences).to eq({ "default_duration_in_min" => [30, 45] })
      end
    end
  end
end
