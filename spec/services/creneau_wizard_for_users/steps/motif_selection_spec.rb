RSpec.describe CreneauWizardForUsers::Steps::MotifSelection do
  describe "#services" do
    it "returns services sort by name" do
      service_a = create(:service, name: "A")
      service_b = create(:service, name: "B")
      motif_a = create(:motif, service: service_a)
      motif_b = create(:motif, service: service_b)
      matching_motifs = Motif.where(id: [motif_a.id, motif_b.id])
      search_context = described_class.new(user: nil, query_params: { motif_name_with_location_type: "" }, starting_conditions:)
      allow(search_context).to receive(:matching_motifs).and_return(matching_motifs)
      expect(search_context.services).to eq([service_a, service_b])
    end
  end

  describe "#service" do
    it "returns service from service_id params when given" do
      service = create(:service)
      search_context = described_class.new(user: nil, query_params: { service_id: service.id }, starting_conditions:)
      expect(search_context.service).to eq(service)
    end

    it "returns service from selected motif" do
      motif = create(:motif)
      matching_motifs = Motif.where(id: motif.id)
      search_context = described_class.new(user: nil, query_params: {}, starting_conditions:)
      allow(search_context).to receive(:matching_motifs).and_return(matching_motifs)
      expect(search_context.service).to eq(motif.service)
    end

    it "returns service from same service motifs" do
      motif = create(:motif)
      autre_motif = create(:motif, service: motif.service)
      matching_motifs = Motif.where(id: [motif.id, autre_motif.id])
      search_context = described_class.new(user: nil, query_params: {}, starting_conditions:)
      allow(search_context).to receive(:matching_motifs).and_return(matching_motifs)
      expect(search_context.service).to eq(motif.service)
    end

    it "returns nil without motifs or service_id" do
      search_context = described_class.new(user: nil, query_params: {}, starting_conditions:)
      matching_motifs = Motif.none
      allow(search_context).to receive(:matching_motifs).and_return(matching_motifs)
      expect(search_context.service).to be_nil
    end

    it "returns nil with multiple service from motifs" do
      motif = create(:motif)
      autre_motif = create(:motif)
      matching_motifs = Motif.where(id: [motif.id, autre_motif.id])
      search_context = described_class.new(user: nil, query_params: {}, starting_conditions:)
      allow(search_context).to receive(:matching_motifs).and_return(matching_motifs)
      expect(search_context.service).to be_nil
    end
  end
end
