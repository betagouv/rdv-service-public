RSpec.describe CreneauWizardForUsers::Steps::CreneauSelection do
  subject(:service) { described_class.new(search_context) }

  let(:user) { create(:user) }
  let(:motif) { create(:motif, default_duration_in_min: 30) }

  before do
    allow(search_context).to receive(:first_matching_motif).and_return(motif)
  end

  describe "#creneaux" do
    context "when lieu is present" do
      let(:search_context) do
        WebSearchContext.new(user:, query_params: { lieu_id: lieu.id })
      end

      let(:lieu) { create(:lieu) }

      it "initializes a CreneauxSearch::ForUser using the lieu and the first matching motif" do
        expect(CreneauxSearch::ForUser).to receive(:new).with(
          user: user,
          motif: motif,
          lieu: lieu,
          date_range: search_context.date_range,
          geo_search: anything,
          duration_in_min: 30
        ).and_call_original

        service.creneaux
      end
    end

    context "when lieu is nil" do
      let!(:motif) { create(:motif, :by_phone, default_duration_in_min: 30) }
      let(:search_context) do
        WebSearchContext.new(user:, query_params: {})
      end

      it "returns a CreneauxSearch::ForUser using no lieu and the selected motif" do
        expect(CreneauxSearch::ForUser).to receive(:new).with(
          user: user,
          motif: motif,
          lieu: nil,
          date_range: search_context.date_range,
          geo_search: anything,
          duration_in_min: 30
        ).and_call_original

        service.creneaux
      end
    end
  end
end
