RSpec.shared_examples "SearchContext" do
  let!(:user) { create(:user, organisations: [organisation]) }
  let!(:organisation) { create(:organisation) }
  let!(:rsa_orientation) { create(:motif_category, name: "RSA orientation sur site", short_name: "rsa_orientation") }
  let!(:motif) { create(:motif, name: "RSA orientation sur site", motif_category: rsa_orientation, organisation: organisation, default_duration_in_min: 30) }
  let!(:rsa_orientation_on_phone_platform) { create(:motif_category, name: "RSA orientation sur plateforme téléphonique", short_name: "rsa_orientation_on_phone_platform") }
  let!(:motif2) { create(:motif, name: "RSA orientation sur plateforme téléphonique", motif_category: rsa_orientation_on_phone_platform, organisation: organisation) }
  let!(:departement_number) { "75" }
  let!(:city_code) { "75007" }
  let!(:latitude) { "48.3" }
  let!(:longitude) { "55.5" }
  let!(:query_params) do
    {
      organisation_ids: [organisation.id], departement: departement_number, city_code: city_code,
      latitude: latitude, longitude: longitude,
    }
  end

  let!(:geo_search) { instance_double(Users::GeoSearch, available_motifs: Motif.where(id: motif.id)) }

  before do
    allow(Users::GeoSearch).to receive(:new)
      .with(departement: departement_number, city_code: city_code, street_ban_id: nil)
      .and_return(geo_search)
  end

  describe "#matching_motifs" do
    it "is the geo search matching motifs" do
      expect(subject.send(:matching_motifs)).to eq([motif])
    end

    context "when there are two available motifs from the geo search" do
      let!(:geo_search) { instance_double(Users::GeoSearch, available_motifs: Motif.where(id: [motif.id, motif2.id])) }

      it "is the returns the two matching motifs" do
        expect(subject.send(:matching_motifs)).to contain_exactly(motif, motif2)
      end
    end
  end

  describe "#filter_motifs" do
    it "returns empty without motifs" do
      search_context = described_class.new(user: nil)
      expect(search_context.filter_motifs(Motif.none)).to be_empty
    end

    it "returns given motif without specific params" do
      search_context = described_class.new(user: nil)
      motif = create(:motif)
      expect(search_context.filter_motifs(Motif.where(id: motif.id))).to eq([motif])
    end

    it "returns collective motif" do
      search_context = described_class.new(user: nil)
      motif = create(:motif, collectif: true)
      expect(search_context.filter_motifs(Motif.where(id: motif.id))).to eq([motif])
    end

    it "returns collective motif with lieu_id" do
      organisation = create(:organisation)
      lieu = create(:lieu, organisation:)
      search_context = described_class.new(user: nil, query_params: { lieu_id: lieu.id })
      motif = create(:motif, collectif: true, organisation:)
      create(:rdv, motif: motif, lieu: lieu, organisation:)
      expect(search_context.filter_motifs(Motif.where(id: motif.id))).to eq([motif])
    end

    it "returns individual motif with lieu_id" do
      lieu = create(:lieu)
      search_context = described_class.new(user: nil, query_params: { lieu_id: lieu.id })
      motif = create(:motif, collectif: false)
      create(:plage_ouverture, motifs: [motif], lieu: lieu)
      expect(search_context.filter_motifs(Motif.where(id: motif.id))).to eq([motif])
    end
  end
end
