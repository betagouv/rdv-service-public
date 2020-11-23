# this file contains ~integration specs, there is another with ~unit tests

describe Users::GeoSearch, type: :service_model do
  context "secto disabled, with a few motifs" do
    subject { Users::GeoSearch.new(departement: "62", city_code: "62100") }

    let!(:organisation1) { create(:organisation, departement: "62", name: "MDS Arques") }
    let!(:organisation2) { create(:organisation, departement: "62", name: "MDS Bapaume") }
    let(:service1) { create(:service) }
    let(:service2) { create(:service) }

    before do
      expect(subject).to receive(:departement_sectorisation_enabled?)
        .at_least(:once)
        .and_return(false)
    end

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

  context "overlapping matching sectors with multiple agents attributed" do
    subject { Users::GeoSearch.new(departement: "62", city_code: "62100") }

    before do
      expect(subject).to receive(:departement_sectorisation_enabled?)
        .at_least(:once)
        .and_return(true)
    end

    let!(:organisation1) { create(:organisation, departement: "62", name: "MDS Arques") }
    let!(:organisation2) { create(:organisation, departement: "62", name: "MDS Bapaume") }
    let(:service1) { create(:service) }
    let(:service2) { create(:service) }

    let!(:motifs_orga1) { create_list(:motif, 5, service: service1, reservable_online: true, organisation: organisation1) }
    let!(:motifs_orga2) { create_list(:motif, 2, service: service1, reservable_online: true, organisation: organisation2) }

    let!(:sector_arques) { create(:sector, departement: "62", name: "Arques CENTRE", human_id: "arques") }
    let!(:zone_arques) { create(:zone, level: "city", city_code: "62100", city_name: "Arques", sector: sector_arques) }
    let!(:sector_ville) { create(:sector, departement: "62", name: "Ville", human_id: "ville") }
    let!(:zone_ville) { create(:zone, level: "city", city_code: "62100", city_name: "Arques", sector: sector_ville) }

    # first agent : sector Arques, orga 1
    let!(:agent_arques1) { create(:agent, organisations: [organisation1]) }
    let!(:attribution_arques1) { SectorAttribution.create(level: "agent", sector: sector_arques, organisation: organisation1, agent: agent_arques1) }
    let!(:plage_ouverture_arques1) { create(:plage_ouverture, agent: agent_arques1, motifs: [motifs_orga1[0], motifs_orga1[1]], organisation: organisation1) }
    let!(:agent_arques_not_attributed) { create(:agent, organisations: [organisation1]) }
    let!(:plage_ouverture_arques_not_attributed) { create(:plage_ouverture, agent: agent_arques_not_attributed, motifs: [motifs_orga1[2]], organisation: organisation1) }

    # second agent : sector Ville, orga 1
    let!(:agent_ville1) { create(:agent, organisations: [organisation1]) }
    let!(:attribution_ville1) { SectorAttribution.create(level: "agent", sector: sector_ville, organisation: organisation1, agent: agent_ville1) }
    let!(:plage_ouverture_ville1) { create(:plage_ouverture, agent: agent_ville1, motifs: [motifs_orga1[4]], organisation: organisation1) }

    # third agent : sector Ville, orga 2
    let!(:agent_ville2) { create(:agent, organisations: [organisation2]) }
    let!(:attribution_ville2) { SectorAttribution.create(level: "agent", sector: sector_ville, organisation: organisation2, agent: agent_ville2) }
    let!(:plage_ouverture_ville2) { create(:plage_ouverture, agent: agent_ville2, motifs: [motifs_orga2[0]], organisation: organisation2) }

    it "should filter accordingly" do
      expect(subject.attributed_organisations).to be_empty
      expect(subject.attributed_agents_by_organisation.keys.flatten).to include(organisation1)
      expect(subject.attributed_agents_by_organisation.keys.flatten).to include(organisation2)
      expect(subject.attributed_agents_by_organisation[organisation1]).to include(agent_arques1)
      expect(subject.attributed_agents_by_organisation[organisation1]).to include(agent_ville1)
      expect(subject.attributed_agents_by_organisation[organisation1]).not_to include(agent_arques_not_attributed)
      expect(subject.attributed_agents_by_organisation[organisation2]).to include(agent_ville2)
      expect(subject.available_motifs).to include(motifs_orga1[0])
      expect(subject.available_motifs).to include(motifs_orga1[1])
      expect(subject.available_motifs).not_to include(motifs_orga1[2])
      expect(subject.available_motifs).not_to include(motifs_orga1[3])
      expect(subject.available_motifs).to include(motifs_orga1[4])
      expect(subject.available_motifs).to include(motifs_orga2[0])
      expect(subject.available_motifs).not_to include(motifs_orga2[1]) # no plage ouvertures
      expect(subject.available_services).to include(service1)
    end
  end

  context "2 sectors splitting a single city into street zones" do
    subject { Users::GeoSearch.new(departement: "62", city_code: "62100") }

    let!(:organisation1) { create(:organisation, departement: "62", name: "MDS Arques") }
    let!(:organisation2) { create(:organisation, departement: "62", name: "MDS Bapaume") }
    let(:service1) { create(:service) }
    let(:service2) { create(:service) }

    let!(:sector_nord) { create(:sector, departement: "62", name: "Arques Nord", human_id: "arques-nord") }
    let!(:zone_nord1) { create(:zone, level: "street", city_code: "62100", city_name: "Arques", street_name: "Rue du machin vert", street_ban_id: "62100_0103", sector: sector_nord) }
    let!(:zone_nord2) { create(:zone, level: "street", city_code: "62100", city_name: "Arques", street_name: "Rue des étoiles", street_ban_id: "62100_2t30", sector: sector_nord) }
    let!(:sector_sud) { create(:sector, departement: "62", name: "Arques Sud", human_id: "arques-sud") }
    let!(:zone_sud1) { create(:zone, level: "street", city_code: "62100", city_name: "Arques", street_name: "Rue du fond", street_ban_id: "62100_304f", sector: sector_sud) }
    let!(:zone_sud2) { create(:zone, level: "street", city_code: "62100", city_name: "Arques", street_name: "Rue des étoiles", street_ban_id: "62100_2t30", sector: sector_sud) }

    let!(:attribution_nord) { SectorAttribution.create(level: "organisation", sector: sector_nord, organisation: organisation1) }
    let!(:attribution_sud) { SectorAttribution.create(level: "organisation", sector: sector_sud, organisation: organisation2) }

    subject { Users::GeoSearch.new(departement: "62", city_code: "62100", street_ban_id: searched_street_ban_id) }

    context "searched street matched zone in sector nord" do
      let(:searched_street_ban_id) { "62100_0103" }
      it "should find the right sector" do
        expect(subject.matching_zones).to contain_exactly(zone_nord1)
        expect(subject.matching_sectors).to contain_exactly(sector_nord)
        expect(subject.attributed_organisations).to contain_exactly(organisation1)
      end
    end

    context "searched street matched zone in sector sud" do
      let(:searched_street_ban_id) { "62100_304f" }
      it "should find the right sector" do
        expect(subject.matching_zones).to contain_exactly(zone_sud1)
        expect(subject.matching_sectors).to contain_exactly(sector_sud)
        expect(subject.attributed_organisations).to contain_exactly(organisation2)
      end
    end

    context "searched street matched in both sectors" do
      let(:searched_street_ban_id) { "62100_2t30" }
      it "should find both sectors" do
        expect(subject.matching_zones).to contain_exactly(zone_nord2, zone_sud2)
        expect(subject.matching_sectors).to contain_exactly(sector_nord, sector_sud)
        expect(subject.attributed_organisations).to contain_exactly(organisation1, organisation2)
      end
    end

    context "searched street not matched" do
      let(:searched_street_ban_id) { "62100_21xx" }
      it "should find nothing" do
        expect(subject.matching_zones).to be_empty
        expect(subject.matching_sectors).to be_empty
        expect(subject.attributed_organisations).to be_empty
      end
    end

    context "with a fallback sector attributed to whole city" do
      let!(:organisation3) { create(:organisation, departement: "62", name: "MDS Arques backup") }

      let!(:sector_fallback) { create(:sector, departement: "62", name: "Arques full", human_id: "arques-fallback") }
      let!(:zone_fallback) { create(:zone, level: "city", city_code: "62100", city_name: "Arques", sector: sector_fallback) }
      let!(:attribution_nord) { SectorAttribution.create(level: "organisation", sector: sector_fallback, organisation: organisation3) }

      context "searched street matched zone in sector sud" do
        let(:searched_street_ban_id) { "62100_304f" }
        it "should find the right sector" do
          expect(subject.matching_zones).to contain_exactly(zone_sud1)
          expect(subject.matching_sectors).to contain_exactly(sector_sud)
          expect(subject.attributed_organisations).to contain_exactly(organisation2)
        end
      end

      context "searched street not matched" do
        let(:searched_street_ban_id) { "62100_21xx" }
        it "should find fallback sector" do
          expect(subject.matching_zones).to contain_exactly(zone_fallback)
          expect(subject.matching_sectors).to contain_exactly(sector_fallback)
          expect(subject.attributed_organisations).to contain_exactly(organisation3)
        end
      end
    end
  end
end
