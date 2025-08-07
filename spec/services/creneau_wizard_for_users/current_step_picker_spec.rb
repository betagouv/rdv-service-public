RSpec.describe CreneauWizardForUsers::CurrentStepPicker do
  subject { described_class.new(search_context).current_step }

  let(:search_context) { WebSearchContext.new(query_params:, user: create(:user)) }

  context "when nothing is passed" do
    let!(:query_params) { {} }

    it "is address selection" do
      expect(subject).to eq(:address_selection)
    end
  end

  context "when using a direct link to an organisation with a territory without departement number" do
    let!(:query_params) { { public_link_organisation_id: organisation.id } }
    let(:departement_number) { nil }
    let(:city_code) { nil }
    let!(:organisation) { create(:organisation, territory: create(:territory, departement_number: "")) }

    it "returns motif selection" do
      expect(subject).to eq(:motif_selection)
    end
  end

  context "with an address" do
    let!(:query_params) { address_params }
    let(:address_params) { { address: "20 avenue de Ségur 75007 Paris", departement: "75", city_code: "75007" } }
    let(:motif) { create(:motif) }
    let(:motif2) { create(:motif) }

    context "and multiple matching motifs" do
      before do
        allow(search_context).to receive(:matching_motifs).and_return([motif, motif2])
      end

      it "is motif selection" do
        expect(subject).to eq(:motif_selection)
      end
    end

    context "and a single matching motif" do
      before do
        allow(search_context).to receive(:matching_motifs).and_return([motif])
      end

      it "is motif selection" do
        expect(subject).to eq(:motif_selection)
      end
    end

    context "with a single matching motif and a motif name in the params" do
      let!(:query_params) do
        address_params.merge(motif_name_with_location_type: motif.name_with_location_type)
      end

      before do
        allow(search_context).to receive(:matching_motifs).and_return([motif])
      end

      it "is lieu selection" do
        expect(subject).to eq(:lieu_selection)
      end
    end
  end
end
