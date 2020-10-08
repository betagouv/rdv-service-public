describe SectoriseAddressService, type: :service do
  let(:service) { SectoriseAddressService.new("62", searched_city_code) }
  subject { service.perform }
  let(:searched_city_code) { "62100" }

  let!(:organisation1) { Organisation.create!(departement: "62", name: "MDS Arques") }
  let!(:organisation2) { Organisation.create!(departement: "62", name: "MDS Bapaume") }

  let!(:sector1) { Sector.create!(departement: "62", name: "Arques VILLE", human_id: "arques") }
  let!(:zone1) { Zone.create(level: "city", city_code: "62100", city_name: "Arques", sector: sector1) }
  let!(:attribution1) { SectorAttribution.create(level: "organisation", sector: sector1, organisation: organisation1) }

  context "sectorisation is disabled for this departement" do
    before { expect(service).to receive(:sectorisation_enabled?).and_return(false) }

    it "should return all organisations from departement" do
      expect(subject.organisations).to contain_exactly(organisation1, organisation2)
    end
  end

  context "sectorisation is enabled" do
    before { expect(service).to receive(:sectorisation_enabled?).and_return(true) }

    it "should return only organisations from matching sector" do
      expect(subject.zones).to contain_exactly(zone1)
      expect(subject.sectors).to contain_exactly(sector1)
      expect(subject.organisations).to contain_exactly(organisation1)
    end

    context "no sector match" do
      let(:searched_city_code) { "62999" }

      it "should return no results" do
        expect(subject.zones).to be_empty
        expect(subject.sectors).to be_empty
        expect(subject.organisations).to be_empty
      end
    end
  end
end
