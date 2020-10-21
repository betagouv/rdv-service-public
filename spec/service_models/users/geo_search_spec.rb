describe Users::GeoSearch, type: :service_model do
  subject { Users::GeoSearch.new("62", searched_city_code) }

  let(:searched_city_code) { "62100" }
  let!(:organisation1) { create(:organisation, departement: "62", name: "MDS Arques") }
  let!(:organisation2) { create(:organisation, departement: "62", name: "MDS Bapaume") }

  let(:service1) { create(:service) }
  let(:service2) { create(:service) }

  before do
    expect(subject).to receive(:departement_sectorisation_enabled?)
      .at_least(:once)
      .and_return(sectorisation_enabled)
  end

  context "sectorisation is disabled for this departement" do
    let(:sectorisation_enabled) { false }

    it "should return all organisations from departement" do
      expect(subject.attributed_organisations).to contain_exactly(organisation1, organisation2)
    end

    context "there are a few motifs" do
      let!(:motif_ok) { create(:motif, service: service1, reservable_online: true, organisation: organisation1) }
      let!(:motif_no_plage_ouverture) { create(:motif, service: service1, reservable_online: true, organisation: organisation1) }
      let!(:motif_service2) { create(:motif, service: service2, reservable_online: true, organisation: organisation1) }
      let!(:motif_orga2) { create(:motif, service: service1, reservable_online: true, organisation: organisation2) }
      let!(:motif_offline) { create(:motif, service: service2, reservable_online: false, organisation: organisation1) }
      let!(:plage_ouverture_ok) { create(:plage_ouverture, motifs: [motif_ok], organisation: organisation1) }
      let!(:plage_ouverture_service2) { create(:plage_ouverture, motifs: [motif_service2], organisation: organisation1) }
      let!(:plage_ouverture_orga2) { create(:plage_ouverture, motifs: [motif_orga2], organisation: organisation2) }
      let!(:plage_ouverture_offline) { create(:plage_ouverture, motifs: [motif_offline], organisation: organisation1) }

      it "should filter available motifs and services" do
        expect(subject.available_motifs).to include(motif_ok)
        expect(subject.available_motifs).to include(motif_service2)
        expect(subject.available_motifs).to include(motif_orga2)
        expect(subject.available_motifs).not_to include(motif_no_plage_ouverture)
        expect(subject.available_motifs).not_to include(motif_offline)
        expect(subject.available_services).to include(service1, service2)
      end
    end
  end

  context "sectorisation is enabled but no sectors match is attributed" do
    let(:sectorisation_enabled) { true }

    it "should return empty results" do
      expect(subject.matching_zones).to be_empty
      expect(subject.matching_sectors).to be_empty
      expect(subject.attributed_organisations).to be_empty
      expect(subject.available_services).to be_empty
      expect(subject.available_motifs).to be_empty
    end
  end

  context "sectorisation is enabled and a sector matches but without any attributions" do
    let(:sectorisation_enabled) { true }
    let!(:sector1) { create(:sector, departement: "62", name: "Arques VILLE", human_id: "arques") }
    let!(:zone1) { create(:zone, level: "city", city_code: "62100", city_name: "Arques", sector: sector1) }

    it "should return empty results" do
      expect(subject.matching_zones).to contain_exactly(zone1)
      expect(subject.matching_sectors).to contain_exactly(sector1)
      expect(subject.attributed_organisations).to be_empty
      expect(subject.available_services).to be_empty
      expect(subject.available_motifs).to be_empty
    end
  end

  context "sectorisation is enabled and an organisation is attributed" do
    let(:sectorisation_enabled) { true }
    let!(:sector1) { create(:sector, departement: "62", name: "Arques VILLE", human_id: "arques") }
    let!(:zone1) { create(:zone, level: "city", city_code: "62100", city_name: "Arques", sector: sector1) }
    let!(:attribution1) { SectorAttribution.create(level: "organisation", sector: sector1, organisation: organisation1) }

    it "should return only organisations from matching sector" do
      expect(subject.matching_zones).to contain_exactly(zone1)
      expect(subject.matching_sectors).to contain_exactly(sector1)
      expect(subject.attributed_organisations).to contain_exactly(organisation1)
    end

    context "there is a single motif with a plage ouverture" do
      let!(:motif) { create(:motif, service: service1, reservable_online: true, organisation: organisation1) }
      let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif]) }

      it "should return the service" do
        expect(subject.available_motifs).to contain_exactly(motif)
        expect(subject.available_services).to contain_exactly(service1)
      end
    end

    context "there are 2 motifs from the same service, one has a plage ouverture, the other doesn't" do
      let!(:motif) { create(:motif, service: service1, reservable_online: true, organisation: organisation1) }
      let!(:motif2) { create(:motif, service: service1, reservable_online: true, organisation: organisation1) }
      let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif]) }

      it "should return only one motif" do
        expect(subject.available_motifs).to contain_exactly(motif)
        expect(subject.available_services).to contain_exactly(service1)
      end
    end

    context "there is only a offline motif" do
      let!(:motif) { create(:motif, service: service1, reservable_online: false, organisation: organisation1) }
      let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif]) }

      it "should not include the service" do
        expect(subject.available_motifs).to be_empty
        expect(subject.available_services).to be_empty
      end
    end

    context "there is a deleted motif" do
      let!(:motif) { create(:motif, service: service1, reservable_online: true, deleted_at: Time.now, organisation: organisation1) }

      it "should not include the service" do
        expect(subject.available_motifs).to be_empty
        expect(subject.available_services).to be_empty
      end
    end

    context "no sector match" do
      let(:searched_city_code) { "62999" }

      it "should return no results" do
        expect(subject.matching_zones).to be_empty
        expect(subject.matching_sectors).to be_empty
        expect(subject.attributed_organisations).to be_empty
      end
    end
  end
end
