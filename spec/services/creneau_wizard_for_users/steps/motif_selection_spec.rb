RSpec.describe CreneauWizardForUsers::Steps::MotifSelection do
  subject(:motif_selection) { described_class.new(search_context) }

  let(:search_context) { WebSearchContext.new(user: nil, query_params: {}) }

  before do
    allow(search_context).to receive(:matching_motifs).and_return(matching_motifs)
  end

  context "when motifs from multiple services are available" do
    let(:motif_a) { create(:motif, service: service_a) }
    let(:motif_b) { create(:motif, service: service_b) }
    let(:service_b) { create(:service, name: "B") }
    let(:service_a) { create(:service, name: "A") }
    let(:matching_motifs) { Motif.where(id: [motif_a.id, motif_b.id]) }

    describe "#services" do
      it "returns services sorted by name" do
        expect(motif_selection.services).to eq([service_a, service_b])
      end
    end

    describe "#service" do
      it "returns nil" do
        expect(motif_selection.service).to be_nil
      end
    end
  end

  describe "#service" do
    context "when there are two motifs for the same service" do
      let(:matching_motifs) { Motif.where(id: [motif.id, autre_motif.id]) }
      let(:autre_motif) { create(:motif, service: motif.service) }
      let(:motif) { create(:motif) }
      let(:search_context) { WebSearchContext.new(user: nil, query_params: {}) }

      it "returns the common service" do
        expect(motif_selection.service).to eq(motif.service)
      end
    end

    context "when no motifs are available" do
      let(:matching_motifs) { Motif.none }
      let(:search_context) { WebSearchContext.new(user: nil, query_params: {}) }

      it "returns nil" do
        expect(motif_selection.service).to be_nil
      end
    end

    context "with a service_id" do
      let(:service) { create(:service) }
      let(:motif) { create(:motif, service: service) }
      let(:search_context) { WebSearchContext.new(user: nil, query_params: { service_id: service.id }) }
      let(:matching_motifs) { Motif.where(id: [motif.id]) }

      it "returns service from service_id params" do
        expect(motif_selection.service).to eq(service)
      end
    end

    context "with a selected motif" do
      let(:motif) { create(:motif) }
      let(:search_context) { WebSearchContext.new(user: nil, query_params: { motif_id: motif.id }) }
      let(:matching_motifs) { Motif.where(id: [motif.id]) }

      it "returns service from selected motif" do
        expect(motif_selection.service).to eq(motif.service)
      end
    end
  end
end
