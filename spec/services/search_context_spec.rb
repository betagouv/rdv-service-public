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
  let!(:motif2) { create(:motif, name: "RSA orientation sur plateforme téléphonique", category: "rsa_orientation_on_phone_platform", organisation: organisation, service: motif.service) }
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

    context "with an address but several motifs available on same service" do
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

  describe "#service" do
    it "returns serice from service_id params when given" do
      service = create(:service)
      search_context = described_class.new(nil, { service_id: service.id })
      expect(search_context.service).to eq(service)
    end

    it "returns service from selected motif" do
      motif = create(:motif)
      search_context = described_class.new(nil, {})
      allow(search_context).to receive(:matching_motifs).and_return([motif])
      expect(search_context.service).to eq(motif.service)
    end

    it "returns service from same service motifs" do
      motif = create(:motif)
      autre_motif = create(:motif, service: motif.service)
      search_context = described_class.new(nil, {})
      allow(search_context).to receive(:matching_motifs).and_return([motif, autre_motif])
      expect(search_context.service).to eq(motif.service)
    end

    it "returns nil without motifs or service_id" do
      search_context = described_class.new(nil, {})
      allow(search_context).to receive(:matching_motifs).and_return([])
      expect(search_context.service).to be_nil
    end

    it "returns nil with multiple service from motifs" do
      motif = create(:motif)
      autre_motif = create(:motif)
      search_context = described_class.new(nil, {})
      allow(search_context).to receive(:matching_motifs).and_return([motif, autre_motif])
      expect(search_context.service).to be_nil
    end
  end

  describe "#creneaux_search" do
    context "when lieu is present" do
      it "returns a Users::CreneauxSearch using the lieu and the first matching motif" do
        plage_ouverture = create(:plage_ouverture, motifs: [motif, motif2], organisation: organisation)
        lieu = plage_ouverture.lieu
        search_context = described_class.new(user, search_query.merge(lieu_id: lieu.id))

        expect(Users::CreneauxSearch).to receive(:new).with(
          user: user,
          motif: motif,
          lieu: lieu,
          date_range: search_context.date_range,
          geo_search: geo_search
        )
        search_context.creneaux_search
      end
    end

    context "when lieu is nil" do
      let!(:motif) { create(:motif, :by_phone, organisation: organisation) }

      it "returns a Users::CreneauxSearch using no lieu and the selected motif" do
        create(:plage_ouverture, lieu: nil, motifs: [motif], organisation: organisation)
        search_context = described_class.new(
          user,
          search_query
        )

        expect(Users::CreneauxSearch).to receive(:new).with(
          user: user,
          motif: motif,
          lieu: nil,
          date_range: search_context.date_range,
          geo_search: geo_search
        )
        search_context.creneaux_search
      end
    end
  end

  describe "#filter_motifs" do
    it "returns empty without motifs" do
      search_context = described_class.new(nil)
      expect(search_context.filter_motifs([])).to be_empty
    end

    it "returns given motif without specific params" do
      search_context = described_class.new(nil)
      motif = create(:motif)
      expect(search_context.filter_motifs(Motif.where(id: motif.id))).to eq([motif])
    end

    it "returns collective motif" do
      search_context = described_class.new(nil)
      motif = create(:motif, collectif: true)
      expect(search_context.filter_motifs(Motif.where(id: motif.id))).to eq([motif])
    end

    it "returns collective motif with lieu_id" do
      lieu = create(:lieu)
      search_context = described_class.new(nil, lieu_id: lieu.id)
      motif = create(:motif, collectif: true)
      create(:rdv, motif: motif, lieu: lieu)
      expect(search_context.filter_motifs(Motif.where(id: motif.id))).to eq([motif])
    end

    it "returns individual motif with lieu_id" do
      lieu = create(:lieu)
      search_context = described_class.new(nil, lieu_id: lieu.id)
      motif = create(:motif, collectif: false)
      create(:plage_ouverture, motifs: [motif], lieu: lieu)
      expect(search_context.filter_motifs(Motif.where(id: motif.id))).to eq([motif])
    end
  end
end
