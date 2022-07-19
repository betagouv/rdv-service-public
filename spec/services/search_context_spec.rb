# frozen_string_literal: true

describe SearchContext, type: :service do
  subject { described_class.new(user, search_query) }

  let!(:user) { create(:user, organisations: [organisation]) }
  let!(:invitation_token) do
    user.invite! { |u| u.skip_invitation = true }
    user.raw_invitation_token
  end
  let!(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }
  let!(:motif) { create(:motif, name: "RSA orientation sur site", category: "rsa_orientation", organisation: organisation) }
  let!(:motif2) { create(:motif, name: "RSA orientation sur plateforme téléphonique", category: "rsa_orientation_on_phone_platform", organisation: organisation) }
  let!(:departement_number) { "75" }
  let!(:address) { "20 avenue de Ségur 75007 Paris" }
  let!(:city_code) { "75007" }
  let!(:latitude) { "48.3" }
  let!(:longitude) { "55.5" }
  let!(:search_query) do
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

  describe "#current_step" do
    context "when nothing is passed" do
      let!(:search_query) { {} }

      it "current step is address selection" do
        expect(subject.current_step).to eq(:address_selection)
      end
    end

    context "with an address but several motifs available" do
      let!(:geo_search) { instance_double(Users::GeoSearch, available_motifs: Motif.where(id: [motif.id, motif2.id])) }
      let!(:search_query) { { address: address, departement: departement_number, city_code: city_code } }

      it "current step is motif selection" do
        expect(subject.current_step).to eq(:motif_selection)
      end
    end

    context "with a motif and an address" do
      let!(:search_query) { { address: address, departement: departement_number, city_code: city_code } }

      it "current step is lieu selection" do
        expect(subject.current_step).to eq(:lieu_selection)
      end
    end
  end

  describe "#matching_motifs" do
    it "is the geo search matching motifs" do
      expect(subject.send(:matching_motifs)).to eq([motif])
    end

    context "for an invitation" do
      before do
        search_query[:invitation_token] = invitation_token
        search_query[:motif_category] = "rsa_orientation"
      end

      context "when there are matching motifs for the geo search" do
        it "is the geo maching motif" do
          expect(subject.send(:matching_motifs)).to eq([motif])
        end
      end

      context "when there are no matching motifs for the geo search" do
        before do
          allow(Motif).to receive(:available_with_plages_ouvertures)
            .and_return(Motif.where(id: motif2.id))
          search_query[:invitation_token] = invitation_token
          search_query[:motif_category] = "rsa_orientation_on_phone_platform"
        end

        it "is the organisation matching motif" do
          expect(subject.send(:matching_motifs)).to eq([motif2])
        end
      end
    end
  end

  describe "#services" do
    it "returns services sort by name" do
      service_a = create(:service, name: "A")
      service_b = create(:service, name: "B")
      motif_a = create(:motif, service: service_a)
      motif_b = create(:motif, service: service_b)
      search_context = described_class.new(nil, motif_name_with_location_type: [])
      allow(search_context).to receive(:matching_motifs).and_return([motif_b, motif_a])
      expect(search_context.services).to eq([service_a, service_b])
    end
  end
end
