describe ImportZoneRowsService, type: :service do
  let!(:orga_arques) { create(:organisation, human_id: "arques", departement: '62') }
  let!(:orga_arras_sud) { create(:organisation, human_id: "arras-sud", departement: '62') }
  let!(:agent) { create(:agent, :admin, organisation_ids: [orga_arques.id, orga_arras_sud.id]) }

  context "valid rows" do
    let(:rows) do
      [
        { "city_code" => "62040", "city_name" => "AIRE-SUR-LA-LYS", "organisation_id" => "arques" },
        { "city_code" => "62110", "city_name" => "ARQUES", "organisation_id" => "arques" },
        { "city_code" => "62007", "city_name" => "ACQ", "organisation_id" => "arras-sud" },
      ]
    end

    it "should be valid and import zones" do
      res = ImportZoneRowsService.perform_with(rows, '62', agent)
      expect(res[:valid]).to eq(true)
      expect(res[:counts][:imported_new]["arques"]).to eq(2)
      expect(res[:counts][:imported_new]["arras-sud"]).to eq(1)
      expect(Zone.count).to eq(3)
      zone1 = Zone.find_by(city_code: 62007)
      expect(zone1.city_name).to eq("ACQ")
      expect(zone1.organisation).to eq(orga_arras_sud)
    end

    context "dry_run" do
      it "should return counters but not actually import" do
        res = ImportZoneRowsService.perform_with(rows, '62', agent, dry_run: true)
        expect(res[:valid]).to eq(true)
        expect(res[:counts][:imported_new]["arques"]).to eq(2)
        expect(res[:counts][:imported_new]["arras-sud"]).to eq(1)
        expect(res[:imported_zones].count).to eq(3)
        expect(Zone.count).to eq(0)
      end
    end
  end

  context "no lines" do
    let(:rows) { [] }
    it "should be invalid" do
      res = ImportZoneRowsService.perform_with(rows, '62', agent)
      expect(res[:valid]).to eq(false)
      expect(res[:errors][0]).to eq("Aucune ligne")
    end
  end

  context "missing required column in header row" do
    let(:rows) do
      [
        { "codeInsee" => "62040", "city_name" => "AIRE-SUR-LA-LYS", "organisation_id" => "arques" },
        { "codeInsee" => "62010", "city_name" => "ARQUES", "organisation_id" => "arques" },
        { "codeInsee" => "62004", "city_name" => "ACHICOURT", "organisation_id" => "arras-nord" },
      ]
    end
    it "should be invalid" do
      res = ImportZoneRowsService.perform_with(rows, '62', agent)
      expect(res[:valid]).to eq(false)
      expect(res[:errors][0]).to eq("Colonne(s) city_code absente(s)")
    end
  end

  context "missing city_code on row" do
    let(:rows) do
      [
        { "city_code" => "62040", "city_name" => "AIRE-SUR-LA-LYS", "organisation_id" => "arques" },
        { "city_code" => "", "city_name" => "ARQUES", "organisation_id" => "arques" },
        { "city_code" => "62004", "city_name" => "ACHICOURT", "organisation_id" => "arras-nord" },
      ]
    end
    it "should be invalid" do
      res = ImportZoneRowsService.perform_with(rows, '62', agent)
      expect(res[:valid]).to eq(false)
      expect(res[:row_errors][1]).to eq("Champ(s) city_code manquant(s)")
    end
  end

  context "missing organisation_id on row" do
    let(:rows) do
      [
        { "city_code" => "62040", "city_name" => "AIRE-SUR-LA-LYS", "organisation_id" => "arques" },
        { "city_code" => "62110", "city_name" => "ARQUES", "organisation_id" => "" },
      ]
    end
    it "should be invalid" do
      res = ImportZoneRowsService.perform_with(rows, '62', agent)
      expect(res[:valid]).to eq(false)
      expect(res[:row_errors][1]).to eq("Champ(s) organisation_id manquant(s)")
    end
  end

  context "no matching organisation for human_id" do
    let(:rows) do
      [
        { "city_code" => "62040", "city_name" => "AIRE-SUR-LA-LYS", "organisation_id" => "arras-nord" },
        { "city_code" => "62004", "city_name" => "ACHICOURT", "organisation_id" => "arras-nord" },
      ]
    end
    it "should not import anything" do
      res = ImportZoneRowsService.perform_with(rows, '62', agent)
      expect(res[:valid]).to eq(false)
      expect(res[:row_errors][0]).to include("Aucune organisation trouvée pour l'identifiant arras-nord")
      expect(Zone.count).to eq(0)
    end
  end

  context "mismatching departement code" do
    let(:rows) do
      [
        { "city_code" => "75040", "city_name" => "AIRE-SUR-LA-LYS", "organisation_id" => "arques" },
      ]
    end
    it "should not import anything" do
      res = ImportZoneRowsService.perform_with(rows, '62', agent)
      expect(res[:valid]).to eq(false)
      expect(res[:row_errors][0]).to include("doit commencer par le département de l'organisation")
      expect(Zone.count).to eq(0)
    end
  end

  context "conflicting rows with same city_code" do
    let(:rows) do
      [
        { "city_code" => "62040", "city_name" => "AIRE-SUR-LA-LYS", "organisation_id" => "arques" },
        { "city_code" => "62040", "city_name" => "AIRE-SUR-LA-LYS", "organisation_id" => "arras-sud" },
      ]
    end

    it "should not import anything" do
      res = ImportZoneRowsService.perform_with(rows, '62', agent)
      expect(res[:valid]).to eq(false)
      expect(res[:errors][0]).to eq("Le code commune 62040 apparaît 2 fois")
      expect(Zone.count).to eq(0)
    end
  end

  context "conflicting existing Zones" do
    let!(:zone) { create(:zone, city_code: 62040, city_name: "AIRE-SUR-LA-LYS", organisation: orga_arras_sud) }
    let(:rows) do
      [
        { "city_code" => "62040", "city_name" => "AIRE-SUR-LA-LYS", "organisation_id" => "arques" },
        { "city_code" => "62004", "city_name" => "ACHICOURT", "organisation_id" => "arques" },
      ]
    end
    context "without override option" do
      it "should not import anything" do
        res = ImportZoneRowsService.perform_with(rows, '62', agent)
        expect(res[:valid]).to eq(false)
        expect(res[:counts][:imported]).to be_empty
        expect(res[:row_errors][0]).to eq("Code de la commune (Code INSEE) n'est pas disponible")
        expect(Zone.count).to eq(1)
        expect(Zone.first.city_code).to eq('62040')
        expect(Zone.first.organisation).to eq(orga_arras_sud) # unchanged
      end
    end
    context "with override option" do
      it "should not import anything" do
        res = ImportZoneRowsService.perform_with(rows, '62', agent, override_conflicts: true)
        expect(res[:row_errors]).to be_empty
        expect(res[:valid]).to eq(true)
        expect(res[:counts][:imported]["arques"]).to eq(2)
        expect(res[:counts][:imported_override]["arques"]).to eq(1)
        expect(res[:counts][:imported_new]["arques"]).to eq(1)
        expect(Zone.count).to eq(2)
        expect(Zone.find_by(city_code: '62040').organisation).to eq(orga_arques)
        expect(Zone.find_by(city_code: '62004').organisation).to eq(orga_arques)
      end
    end
  end

  context "organisation exists in same departement, but agent unauthorized" do
    let!(:orga_arras_nord) { create(:organisation, human_id: "arras-nord", departement: '62') }

    let(:rows) do
      [
        { "city_code" => "62040", "city_name" => "AIRE-SUR-LA-LYS", "organisation_id" => "arques" },
        { "city_code" => "62007", "city_name" => "ACQ", "organisation_id" => "arras-nord" },
      ]
    end

    it "should not import anything" do
      res = ImportZoneRowsService.perform_with(rows, '62', agent)
      expect(res[:valid]).to eq(false)
      expect(res[:row_errors][1]).to include("Pas les droits nécessaires")
      expect(Zone.count).to eq(0)
    end
  end
end
