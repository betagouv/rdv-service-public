RSpec.describe MotifsComparisonPresenter do
  describe "#displayed_pairs" do
    let(:service_pmi) { create(:service, :pmi) }
    let(:service_social) { create(:service, :social) }

    let(:org_a) do
      create(:organisation).tap do |org_a|
        org_a.motifs = [
          create(:motif, organisation: org_a, name: "Première consultation", service: service_pmi, location_type: :public_office),
          create(:motif, organisation: org_a, name: "Première consultation", service: service_social, location_type: :public_office),
        ]
      end
    end

    let(:org_b) do
      create(:organisation).tap do |org_b|
        org_a.motifs = [
          create(:motif, organisation: org_b, name: "Première consultation", service: service_pmi, location_type: :public_office),
          create(:motif, organisation: org_b, name: "Première consultation", service: service_social, location_type: :public_office),
        ]
      end
    end

    it "works 1" do
      presenter = described_class.new(org_a, org_b, show_all_attrs: true, only_different_pairs: true)
      expect(presenter.displayed_pairs.size).to eq(0)

      # Set only_different_pairs to false
      presenter = described_class.new(org_a, org_b, show_all_attrs: true, only_different_pairs: false)
      expect(presenter.displayed_pairs.size).to eq(2)
    end
  end

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
