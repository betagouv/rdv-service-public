describe ExportZonesService, type: :service do
  describe "#perform" do
    let!(:territory) { create(:territory, name: "Yvelines", departement_number: "78") }
    let!(:sector1) { create(:sector, name: "Yvelines Sud", human_id: "78-sud", territory: territory) }
    let!(:zone11) { create(:zone, sector: sector1, city_code: "78000", city_name: "Versailles") }
    let!(:sector2) { create(:sector, name: "Yvelines Nord", human_id: "78-nord", territory: territory) }
    let!(:zone21) { create(:zone, sector: sector2, city_code: "78370", city_name: "Plaisir") }
    let!(:zone22) { create(:zone, :level_street, sector: sector2, city_code: "78180", city_name: "Élancourt", street_name: "Rue du Hall", street_ban_id: "78180_001") }
    let!(:zone23) { create(:zone, :level_street, sector: sector2, city_code: "78180", city_name: "Élancourt", street_name: "Rue Allo Allo", street_ban_id: "78180_002") }

    subject { ExportZonesService.new(Zone.in_territory(territory)).perform }

    it "should work and order correctly" do
      rows = xls_bytes_to_rows(subject)
      expect(rows.count).to eq 4
      expect(rows[0][:sector_name]).to eq("Yvelines Nord")
      expect(rows[0][:sector_id]).to eq("78-nord")
      expect(rows[0][:city_code]).to eq("78180")
      expect(rows[0][:city_name]).to eq("Élancourt")
      expect(rows[0][:street_name]).to eq("Rue Allo Allo")
      expect(rows[0][:street_code]).to eq("78180_002")

      expect(rows[1][:sector_name]).to eq("Yvelines Nord")
      expect(rows[1][:sector_id]).to eq("78-nord")
      expect(rows[1][:city_code]).to eq("78180")
      expect(rows[1][:city_name]).to eq("Élancourt")
      expect(rows[1][:street_name]).to eq("Rue du Hall")
      expect(rows[1][:street_code]).to eq("78180_001")

      expect(rows[2][:sector_name]).to eq("Yvelines Nord")
      expect(rows[2][:sector_id]).to eq("78-nord")
      expect(rows[2][:city_code]).to eq("78370")
      expect(rows[2][:city_name]).to eq("Plaisir")
      expect(rows[2][:street_name]).to be_blank
      expect(rows[2][:street_code]).to be_blank

      expect(rows[3][:sector_name]).to eq("Yvelines Sud")
      expect(rows[3][:sector_id]).to eq("78-sud")
      expect(rows[3][:city_code]).to eq("78000")
      expect(rows[3][:city_name]).to eq("Versailles")
      expect(rows[3][:street_name]).to be_blank
      expect(rows[3][:street_code]).to be_blank
    end
  end

  def xls_bytes_to_rows(xls_bytes)
    Tempfile.create("zones.xls", encoding: "ascii-8bit") do |file|
      file.write(xls_bytes)
      file.rewind
      rows_as_arrays = Spreadsheet.open(file.path).worksheets.first.map(&:to_a)
      return rows_as_arrays[1..].map { rows_as_arrays[0].zip(_1).to_h.symbolize_keys }
    end
  end
end
