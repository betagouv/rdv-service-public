RSpec.describe CreneauWizardForUsers::CurrentStepPicker do
  subject { described_class.new(context) }

  let(:context) do
    double(query_params:, first_matching_motif:)
  end

  let(:first_matching_motif) { nil }

  context "when nothing is passed" do
    let!(:query_params) { {} }

    it "current step is address selection" do
      expect(subject.current_step).to eq(:address_selection)
    end
  end

  context "when using a direct link to an organisation with a territory without departement number" do
    let!(:query_params) { { public_link_organisation_id: organisation.id } }
    let(:departement_number) { nil }
    let(:city_code) { nil }
    let!(:organisation) { create(:organisation, territory: create(:territory, departement_number: "")) }

    it "returns motif selection" do
      expect(subject.current_step).to eq(:motif_selection)
    end
  end

  context "with an address but several matching motifs" do
    let!(:geo_search) { instance_double(Users::GeoSearch, available_motifs: Motif.where(id: [motif.id, motif2.id])) }
    let!(:query_params) { { address: address, departement: departement_number, city_code: city_code } }

    it "current step is motif selection" do
      expect(subject.current_step).to eq(:motif_selection)
    end
  end

  context "with a single matching motif and an address" do
    let!(:query_params) { { address: address, departement: departement_number, city_code: city_code } }

    it "current step is motif selection" do
      expect(subject.current_step).to eq(:motif_selection)
    end
  end

  context "with a single matching motif and an address and a motif name in the params" do
    let!(:query_params) { { address: address, departement: departement_number, city_code: city_code, motif_name_with_location_type: motif.name_with_location_type } }

    it "current step is lieu selection" do
      expect(subject.current_step).to eq(:lieu_selection)
    end
  end
end
