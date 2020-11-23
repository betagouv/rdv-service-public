# this file contains ~unit tests, there is another with ~integration specs

describe Users::GeoSearch, type: :service_model do
  before do
    expect_any_instance_of(Users::GeoSearch).to receive(:departement_sectorisation_enabled?)
      .at_least(:once)
      .and_return(true)
  end

  describe "#matching_zones" do
    subject { Users::GeoSearch.new(departement: "62", city_code: "62100").matching_zones }

    context "organisation exist but no zones" do
      let!(:organisation) { create(:organisation, departement: "62", name: "MDS Arques") }
      it { should be_empty }
    end

    context "city-zones match" do
      let!(:zone1) { create(:zone, level: "city", city_code: "62100", city_name: "Arques") }
      let!(:zone2) { create(:zone, level: "city", city_code: "62100", city_name: "Arques") }
      let!(:zone_mismatch) { create(:zone, level: "city", city_code: "62300", city_name: "Arques") }
      it { should contain_exactly(zone1, zone2) }
    end
  end

  describe "#matching_sectors" do
    subject { Users::GeoSearch.new(departement: "62", city_code: "62100").matching_sectors }

    context "organisation exist but no zones or sectors" do
      let!(:organisation) { create(:organisation, departement: "62", name: "MDS Arques") }
      it { should be_empty }
    end

    context "city-zones match" do
      let!(:sector1) { create(:sector, departement: "62", name: "Arques 1", human_id: "arques-1") }
      let!(:zone1) { create(:zone, level: "city", city_code: "62100", city_name: "Arques", sector: sector1) }
      let!(:sector2) { create(:sector, departement: "62", name: "Arques 2", human_id: "arques-2") }
      let!(:zone2) { create(:zone, level: "city", city_code: "62100", city_name: "Arques", sector: sector2) }
      let!(:sector_mismatch) { create(:sector, departement: "62", name: "Bapaume", human_id: "bapaume") }
      let!(:zone_mismatch) { create(:zone, level: "city", city_code: "62300", city_name: "Bapaume") }
      it { should contain_exactly(sector1, sector2) }
    end
  end

  describe "#attributed_organisations" do
    subject { Users::GeoSearch.new(departement: "62", city_code: "62100").attributed_organisations }

    context "no matching sectors" do
      it { should be_empty }
    end

    context "matching sector attributed to orga" do
      let!(:organisation) { create(:organisation, departement: "62", name: "MDS Arques") }
      let!(:sector) { create(:sector, departement: "62", name: "Arques VILLE", human_id: "arques") }
      let!(:zone) { create(:zone, level: "city", city_code: "62100", city_name: "Arques", sector: sector) }
      let!(:attribution) { create(:sector_attribution, :level_organisation, sector: sector, organisation: organisation) }
      it { should contain_exactly(organisation) }
    end

    context "matching sector attributed to agent" do
      let!(:organisation) { create(:organisation, departement: "62", name: "MDS Arques") }
      let!(:sector) { create(:sector, departement: "62", name: "Arques VILLE", human_id: "arques") }
      let!(:zone) { create(:zone, level: "city", city_code: "62100", city_name: "Arques", sector: sector) }
      let!(:attribution) { create(:sector_attribution, :level_agent, sector: sector, organisation: organisation) }
      it { should_not contain_exactly(organisation) }
    end

    context "matching sector attributed to multiple organisations" do
      let!(:organisation1) { create(:organisation, departement: "62", name: "MDS Arques Nord") }
      let!(:organisation2) { create(:organisation, departement: "62", name: "MDS Arques Sud") }
      let!(:organisation_not_attributed) { create(:organisation, departement: "62") }
      let!(:sector) { create(:sector, departement: "62", name: "Arques VILLE", human_id: "arques") }
      let!(:zone) { create(:zone, level: "city", city_code: "62100", city_name: "Arques", sector: sector) }
      let!(:attribution1) { create(:sector_attribution, :level_organisation, sector: sector, organisation: organisation1) }
      let!(:attribution2) { create(:sector_attribution, :level_organisation, sector: sector, organisation: organisation2) }
      it { should contain_exactly(organisation1, organisation2) }
    end

    context "matching sectors attributed to different organisations" do
      let!(:organisation1) { create(:organisation, departement: "62", name: "MDS Arques Nord") }
      let!(:organisation2) { create(:organisation, departement: "62", name: "MDS Arques Sud") }
      let!(:sector1) { create(:sector, departement: "62", name: "Arques VILLE", human_id: "arques-nord") }
      let!(:sector2) { create(:sector, departement: "62", name: "Arques Sud", human_id: "arques-sud") }
      let!(:zone1) { create(:zone, level: "city", city_code: "62100", city_name: "Arques", sector: sector1) }
      let!(:zone2) { create(:zone, level: "city", city_code: "62100", city_name: "Arques", sector: sector2) }
      let!(:attribution1) { create(:sector_attribution, :level_organisation, sector: sector1, organisation: organisation1) }
      let!(:attribution2) { create(:sector_attribution, :level_organisation, sector: sector2, organisation: organisation2) }
      it { should contain_exactly(organisation1, organisation2) }
    end

    context "edge case: one matching sector attributed to full orga, other matching sector attributed to agent in same orga" do
      let!(:organisation) { create(:organisation, departement: "62", name: "MDS Arques") }
      let!(:sector_arques_rural) { create(:sector, departement: "62", name: "Arques CENTRE", human_id: "arques") }
      let!(:zone_arques_rural) { create(:zone, level: "city", city_code: "62100", city_name: "Arques", sector: sector_arques_rural) }
      let!(:sector_arques_ville) { create(:sector, departement: "62", name: "Ville", human_id: "ville") }
      let!(:zone_arques_ville) { create(:zone, level: "city", city_code: "62100", city_name: "Arques", sector: sector_arques_ville) }
      let!(:agent) { create(:agent, organisations: [organisation]) }
      let!(:attribution_organisation_arques_rural) { SectorAttribution.create(level: "organisation", sector: sector_arques_rural, organisation: organisation) }
      let!(:attribution_agent_arques_ville) { SectorAttribution.create(level: "agent", sector: sector_arques_ville, organisation: organisation, agent: agent) }
      it { should contain_exactly(organisation) }
    end
  end

  describe "#attributed_agents_by_organisation" do
    subject { Users::GeoSearch.new(departement: "62", city_code: "62100").attributed_agents_by_organisation }

    context "one agent attributed with online motif" do
      let!(:organisation) { create(:organisation, departement: "62", name: "MDS Arques") }
      let!(:agent) { create(:agent, organisations: [organisation]) }
      let!(:motif) { create(:motif, reservable_online: true, organisation: organisation) }
      let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif], organisation: organisation, agent: agent) }
      let!(:sector) { create(:sector, departement: "62", name: "Arques VILLE", human_id: "arques") }
      let!(:zone) { create(:zone, level: "city", city_code: "62100", city_name: "Arques", sector: sector) }
      let!(:attribution) { create(:sector_attribution, :level_agent, sector: sector, organisation: organisation, agent: agent) }
      it { should eq({ organisation => [agent] }) }
    end

    context "edge case: sector attributed to full orga + other sector attributed to agent in same orga" do
      let!(:organisation) { create(:organisation, departement: "62", name: "MDS Arques") }
      let!(:sector_arques_rural) { create(:sector, departement: "62", name: "Arques CENTRE", human_id: "arques") }
      let!(:zone_arques_rural) { create(:zone, level: "city", city_code: "62100", city_name: "Arques", sector: sector_arques_rural) }
      let!(:sector_arques_ville) { create(:sector, departement: "62", name: "Ville", human_id: "ville") }
      let!(:zone_arques_ville) { create(:zone, level: "city", city_code: "62100", city_name: "Arques", sector: sector_arques_ville) }
      let!(:agent) { create(:agent, organisations: [organisation]) }
      let!(:attribution_organisation_arques_rural) { SectorAttribution.create(level: "organisation", sector: sector_arques_rural, organisation: organisation) }
      let!(:attribution_agent_arques_ville) { SectorAttribution.create(level: "agent", sector: sector_arques_ville, organisation: organisation, agent: agent) }
      it { should be_empty } # orga match supersedes, we want no duplication
    end
  end

  describe "#available_motifs" do
    subject { Users::GeoSearch.new(departement: "62", city_code: "62100").available_motifs }

    context "no organisations in departement" do
      it { should be_empty }
    end

    context "matching sector not attributed" do
      let!(:organisation) { create(:organisation, departement: "62", name: "MDS Arques") }
      let!(:sector) { create(:sector, departement: "62", name: "Arques VILLE", human_id: "arques") }
      let!(:zone) { create(:zone, level: "city", city_code: "62100", city_name: "Arques", sector: sector) }
      it { should be_empty }
    end

    context "matching sector attributed to orga" do
      let!(:organisation) { create(:organisation, departement: "62", name: "MDS Arques") }
      let!(:motif) { create(:motif, reservable_online: true, organisation: organisation) }
      let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif], organisation: organisation) }
      let!(:sector) { create(:sector, departement: "62", name: "Arques VILLE", human_id: "arques") }
      let!(:zone) { create(:zone, level: "city", city_code: "62100", city_name: "Arques", sector: sector) }
      let!(:attribution) { create(:sector_attribution, :level_organisation, sector: sector, organisation: organisation) }
      it { should contain_exactly(motif) }
    end

    context "2 motifs with 2 plage ouvertures match" do
      let!(:organisation) { create(:organisation, departement: "62", name: "MDS Arques") }
      let!(:motif1) { create(:motif, reservable_online: true, organisation: organisation) }
      let!(:plage_ouverture1) { create(:plage_ouverture, motifs: [motif1], organisation: organisation) }
      let!(:motif2) { create(:motif, reservable_online: true, organisation: organisation) }
      let!(:plage_ouverture2) { create(:plage_ouverture, motifs: [motif2], organisation: organisation) }
      let!(:sector) { create(:sector, departement: "62", name: "Arques VILLE", human_id: "arques") }
      let!(:zone) { create(:zone, level: "city", city_code: "62100", city_name: "Arques", sector: sector) }
      let!(:attribution) { create(:sector_attribution, :level_organisation, sector: sector, organisation: organisation) }
      it { should contain_exactly(motif1, motif2) }
    end

    context "2 motifs, one without plage ouverture" do
      let!(:organisation) { create(:organisation, departement: "62", name: "MDS Arques") }
      let!(:motif1) { create(:motif, reservable_online: true, organisation: organisation) }
      let!(:plage_ouverture1) { create(:plage_ouverture, motifs: [motif1], organisation: organisation) }
      let!(:motif2) { create(:motif, reservable_online: true, organisation: organisation) }
      let!(:sector) { create(:sector, departement: "62", name: "Arques VILLE", human_id: "arques") }
      let!(:zone) { create(:zone, level: "city", city_code: "62100", city_name: "Arques", sector: sector) }
      let!(:attribution) { create(:sector_attribution, :level_organisation, sector: sector, organisation: organisation) }
      it { should contain_exactly(motif1) }
    end

    context "2 motifs, one offline" do
      let!(:organisation) { create(:organisation, departement: "62", name: "MDS Arques") }
      let!(:motif1) { create(:motif, reservable_online: true, organisation: organisation) }
      let!(:plage_ouverture1) { create(:plage_ouverture, motifs: [motif1], organisation: organisation) }
      let!(:motif2) { create(:motif, reservable_online: false, organisation: organisation) }
      let!(:plage_ouverture2) { create(:plage_ouverture, motifs: [motif2], organisation: organisation) }
      let!(:sector) { create(:sector, departement: "62", name: "Arques VILLE", human_id: "arques") }
      let!(:zone) { create(:zone, level: "city", city_code: "62100", city_name: "Arques", sector: sector) }
      let!(:attribution) { create(:sector_attribution, :level_organisation, sector: sector, organisation: organisation) }
      it { should contain_exactly(motif1) }
    end

    context "2 motifs, one deleted" do
      let!(:organisation) { create(:organisation, departement: "62", name: "MDS Arques") }
      let!(:motif1) { create(:motif, reservable_online: true, organisation: organisation) }
      let!(:plage_ouverture1) { create(:plage_ouverture, motifs: [motif1], organisation: organisation) }
      let!(:motif2) { create(:motif, reservable_online: true, organisation: organisation, deleted_at: 2.hours.ago) }
      let!(:plage_ouverture2) { create(:plage_ouverture, motifs: [motif2], organisation: organisation) }
      let!(:sector) { create(:sector, departement: "62", name: "Arques VILLE", human_id: "arques") }
      let!(:zone) { create(:zone, level: "city", city_code: "62100", city_name: "Arques", sector: sector) }
      let!(:attribution) { create(:sector_attribution, :level_organisation, sector: sector, organisation: organisation) }
      it { should contain_exactly(motif1) }
    end

    context "1 motif coming from attributed agent, 1 from attributed orga" do
      let!(:organisation1) { create(:organisation, departement: "62", name: "MDS Arques") }
      let!(:organisation2) { create(:organisation, departement: "62", name: "MDS Arras") }
      let!(:agent) { create(:agent, organisations: [organisation2]) }

      let!(:motif_organisation) { create(:motif, reservable_online: true, organisation: organisation1) }
      let!(:motif_agent) { create(:motif, reservable_online: true, organisation: organisation2) }

      let!(:plage_ouverture_organisation) { create(:plage_ouverture, motifs: [motif_organisation], organisation: organisation1) }
      let!(:plage_ouverture_agent) { create(:plage_ouverture, motifs: [motif_agent], organisation: organisation2, agent: agent) }

      let!(:sector_organisation) { create(:sector, departement: "62", name: "Arques 1", human_id: "arques-1") }
      let!(:zone_organisation) { create(:zone, level: "city", city_code: "62100", city_name: "Arques", sector: sector_organisation) }
      let!(:attribution_organisation) { create(:sector_attribution, :level_organisation, sector: sector_organisation, organisation: organisation1) }

      let!(:sector_agent) { create(:sector, departement: "62", name: "Arques 2", human_id: "arques-2") }
      let!(:zone_agent) { create(:zone, level: "city", city_code: "62100", city_name: "Arques", sector: sector_agent) }
      let!(:attribution_agent) { create(:sector_attribution, :level_agent, sector: sector_agent, organisation: organisation2, agent: agent) }

      it { should contain_exactly(motif_organisation, motif_agent) }
    end
  end

  describe "#available_services" do
    subject { Users::GeoSearch.new(departement: "62", city_code: "62100").available_services }

    context "organisation exist but no sectors" do
      let!(:organisation) { create(:organisation, departement: "62", name: "MDS Arques") }
      it { should be_empty }
    end

    context "matching sector with 2 motifs with POs from different services" do
      let!(:organisation) { create(:organisation, departement: "62", name: "MDS Arques") }
      let!(:service1) { create(:service) }
      let!(:service2) { create(:service) }
      let!(:motif1) { create(:motif, reservable_online: true, organisation: organisation, service: service1) }
      let!(:plage_ouverture1) { create(:plage_ouverture, motifs: [motif1], organisation: organisation) }
      let!(:motif2) { create(:motif, reservable_online: true, organisation: organisation, service: service2) }
      let!(:plage_ouverture2) { create(:plage_ouverture, motifs: [motif2], organisation: organisation) }
      let!(:sector) { create(:sector, departement: "62", name: "Arques VILLE", human_id: "arques") }
      let!(:zone) { create(:zone, level: "city", city_code: "62100", city_name: "Arques", sector: sector) }
      let!(:attribution) { create(:sector_attribution, :level_organisation, sector: sector, organisation: organisation) }
      it { should contain_exactly(service1, service2) }
    end

    context "matching sector with 2 motifs with POs from same service" do
      let!(:organisation) { create(:organisation, departement: "62", name: "MDS Arques") }
      let!(:service) { create(:service) }
      let!(:motif1) { create(:motif, reservable_online: true, organisation: organisation, service: service) }
      let!(:plage_ouverture1) { create(:plage_ouverture, motifs: [motif1], organisation: organisation) }
      let!(:motif2) { create(:motif, reservable_online: true, organisation: organisation, service: service) }
      let!(:plage_ouverture2) { create(:plage_ouverture, motifs: [motif2], organisation: organisation) }
      let!(:sector) { create(:sector, departement: "62", name: "Arques VILLE", human_id: "arques") }
      let!(:zone) { create(:zone, level: "city", city_code: "62100", city_name: "Arques", sector: sector) }
      let!(:attribution) { create(:sector_attribution, :level_organisation, sector: sector, organisation: organisation) }
      it { should contain_exactly(service) } # we expect no duplicates
    end
  end
end
