RSpec.describe ImportZoneRowsService, type: :service do
  # TODO: this spec should mock ZoneImportRow calls and tests should be moved

  let!(:territory62) { create(:territory, departement_number: "62") }
  let!(:orga62) { create(:organisation, territory: territory62) }
  let!(:sector_arques) { create(:sector, human_id: "arques", territory: territory62) }
  let!(:sector_arras_sud) { create(:sector, human_id: "arras-sud", territory: territory62) }
  let!(:agent) { create(:agent, admin_role_in_organisations: [orga62], role_in_territories: [territory62]) }

  context "valid rows" do
    let(:rows) do
      [
        { "city_code" => "62040", "city_name" => "AIRE-SUR-LA-LYS", "sector_id" => "arques" },
        { "city_code" => "62110", "city_name" => "ARQUES", "sector_id" => "arques" },
        { "city_code" => "62007", "city_name" => "ACQ", "sector_id" => "arras-sud" },
      ]
    end

    it "is valid and import zones" do
      res = described_class.perform_with(rows, territory62, agent)
      expect(res[:valid]).to be(true)
      expect(res[:counts][:imported_new]["arques"]).to eq(2)
      expect(res[:counts][:imported_new]["arras-sud"]).to eq(1)
      expect(Zone.count).to eq(3)
      zone1 = Zone.find_by(city_code: 62_007)
      expect(zone1.city_name).to eq("ACQ")
      expect(zone1.sector).to eq(sector_arras_sud)
    end

    context "dry_run" do
      it "returns counters but not actually import" do
        res = described_class.perform_with(rows, territory62, agent, dry_run: true)
        expect(res[:valid]).to be(true)
        expect(res[:counts][:imported_new]["arques"]).to eq(2)
        expect(res[:counts][:imported_new]["arras-sud"]).to eq(1)
        expect(res[:imported_zones].count).to eq(3)
        expect(Zone.count).to eq(0)
      end
    end
  end

  context "valid rows with streets" do
    let(:rows) do
      [
        { "city_code" => "62040", "city_name" => "AIRE-SUR-LA-LYS", "sector_id" => "arques" },
        { "city_code" => "62080", "city_name" => "BAPAUME", "sector_id" => "arras-sud", "street_name" => "rue de la gare", "street_code" => "62080_0580" },
        { "city_code" => "62080", "city_name" => "BAPAUME", "sector_id" => "arras-sud", "street_name" => "rue des casernes", "street_code" => "62080_0180" },
      ]
    end

    it "is valid and import zones" do
      res = described_class.perform_with(rows, territory62, agent)
      expect(res[:valid]).to be(true)
      expect(res[:counts][:imported_new]["arques"]).to eq(1)
      expect(res[:counts][:imported_new]["arras-sud"]).to eq(2)
      expect(Zone.count).to eq(3)
      expect(Zone.cities.count).to eq(1)
      expect(Zone.streets.count).to eq(2)
      expect(Zone.where(city_code: "62080").count).to eq(2)
      expect(Zone.where(city_code: "62080").first.sector).to eq(sector_arras_sud)
      expect(Zone.where(city_code: "62080").pluck(:street_ban_id)).to contain_exactly("62080_0580", "62080_0180")
    end

    context "dry_run" do
      it "returns counters but not actually import" do
        res = described_class.perform_with(rows, territory62, agent, dry_run: true)
        expect(res[:valid]).to be(true)
        expect(res[:counts][:imported_new]["arques"]).to eq(1)
        expect(res[:counts][:imported_new]["arras-sud"]).to eq(2)
        expect(res[:imported_zones].count).to eq(3)
        expect(Zone.count).to eq(0)
      end
    end
  end

  context "no lines" do
    let(:rows) { [] }

    it "is invalid" do
      res = described_class.perform_with(rows, territory62, agent)
      expect(res[:valid]).to be(false)
      expect(res[:errors][0]).to eq("Aucune ligne")
    end
  end

  context "missing required column in header row" do
    let(:rows) do
      [
        { "codeInsee" => "62040", "city_name" => "AIRE-SUR-LA-LYS", "sector_id" => "arques" },
        { "codeInsee" => "62010", "city_name" => "ARQUES", "sector_id" => "arques" },
        { "codeInsee" => "62004", "city_name" => "ACHICOURT", "sector_id" => "arras-nord" },
      ]
    end

    it "is invalid" do
      res = described_class.perform_with(rows, territory62, agent)
      expect(res[:valid]).to be(false)
      expect(res[:errors][0]).to eq("Colonne(s) city_code absente(s)")
    end
  end

  context "missing city_code on row" do
    let(:rows) do
      [
        { "city_code" => "62040", "city_name" => "AIRE-SUR-LA-LYS", "sector_id" => "arques" },
        { "city_code" => "", "city_name" => "ARQUES", "sector_id" => "arques" },
        { "city_code" => "62004", "city_name" => "ACHICOURT", "sector_id" => "arras-nord" },
      ]
    end

    it "is invalid" do
      res = described_class.perform_with(rows, territory62, agent)
      expect(res[:valid]).to be(false)
      expect(res[:row_errors][1]).to eq("Champ(s) city_code manquant(s)")
    end
  end

  context "missing sector_id on row" do
    let(:rows) do
      [
        { "city_code" => "62040", "city_name" => "AIRE-SUR-LA-LYS", "sector_id" => "arques" },
        { "city_code" => "62110", "city_name" => "ARQUES", "sector_id" => "" },
      ]
    end

    it "is invalid" do
      res = described_class.perform_with(rows, territory62, agent)
      expect(res[:valid]).to be(false)
      expect(res[:row_errors][1]).to eq("Champ(s) sector_id manquant(s)")
    end
  end

  context "no matching sector for human_id" do
    let(:rows) do
      [
        { "city_code" => "62040", "city_name" => "AIRE-SUR-LA-LYS", "sector_id" => "arras-nord" },
        { "city_code" => "62004", "city_name" => "ACHICOURT", "sector_id" => "arras-nord" },
      ]
    end

    it "does not import anything" do
      res = described_class.perform_with(rows, territory62, agent)
      expect(res[:valid]).to be(false)
      expect(res[:row_errors][0]).to include("Aucun secteur trouvé pour l'identifiant arras-nord")
      expect(Zone.count).to eq(0)
    end
  end

  context "mismatching departement code" do
    let(:rows) do
      [
        { "city_code" => "75040", "city_name" => "AIRE-SUR-LA-LYS", "sector_id" => "arques" },
      ]
    end

    it "does not import anything" do
      res = described_class.perform_with(rows, territory62, agent)
      expect(res[:valid]).to be(false)
      expect(res[:row_errors][0]).to include("La commune AIRE-SUR-LA-LYS n'appartient pas au département 62")
      expect(Zone.count).to eq(0)
    end
  end

  context "conflicting rows with same city_code" do
    let(:rows) do
      [
        { "city_code" => "62040", "city_name" => "AIRE-SUR-LA-LYS", "sector_id" => "arques" },
        { "city_code" => "62040", "city_name" => "AIRE-SUR-LA-LYS", "sector_id" => "arras-sud" },
      ]
    end

    it "does not import anything" do
      res = described_class.perform_with(rows, territory62, agent)
      expect(res[:valid]).to be(false)
      expect(res[:errors][0]).to eq("Le code commune 62040 apparaît 2 fois")
      expect(Zone.count).to eq(0)
    end
  end

  context "conflicting existing Zones" do
    let!(:zone) { create(:zone, city_code: 62_040, city_name: "AIRE-SUR-LA-LYS", sector: sector_arques) }
    let(:rows) do
      [
        { "city_code" => "62040", "city_name" => "AIRE-SUR-LA-lièsse", "sector_id" => "arques" },
        { "city_code" => "62004", "city_name" => "ACHICOURT", "sector_id" => "arques" },
      ]
    end

    it "imports and override existing zones" do
      res = described_class.perform_with(rows, territory62, agent)
      expect(res[:row_errors]).to be_empty
      expect(res[:valid]).to be(true)
      expect(res[:counts][:imported]["arques"]).to eq(2)
      expect(res[:counts][:imported_override]["arques"]).to eq(1)
      expect(res[:counts][:imported_new]["arques"]).to eq(1)
      expect(Zone.count).to eq(2)
      expect(Zone.find_by(city_code: "62040").sector).to eq(sector_arques)
      expect(Zone.find_by(city_code: "62040").city_name).to eq("AIRE-SUR-LA-lièsse") # changed
      expect(Zone.find_by(city_code: "62004").sector).to eq(sector_arques)
    end
  end

  context "zone for the same city exists in another sector" do
    let!(:zone) { create(:zone, city_code: 62_040, city_name: "AIRE-SUR-LA-LYS", sector: sector_arras_sud) }
    let(:rows) do
      [
        { "city_code" => "62040", "city_name" => "AIRE-SUR-LA-lièsse", "sector_id" => "arques" },
        { "city_code" => "62004", "city_name" => "ACHICOURT", "sector_id" => "arques" },
      ]
    end

    it "imports anyway" do
      res = described_class.perform_with(rows, territory62, agent)
      expect(res[:valid]).to be(true)
      expect(res[:counts][:imported]["arques"]).to eq(2)
      expect(Zone.count).to eq(3)
      expect(Zone.where(city_code: "62040").count).to eq(2)
      expect(Zone.find_by(city_code: "62040", sector: sector_arras_sud).city_name).to eq("AIRE-SUR-LA-LYS")
      expect(Zone.find_by(city_code: "62040", sector: sector_arques).city_name).to eq("AIRE-SUR-LA-lièsse")
    end
  end
end
