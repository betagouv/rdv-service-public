describe MonthlyStatsExporterService, type: :service do
  context "with a sheet inside" do
    it "have an header" do
      sheet = MonthlyStatsExporterService.new([], StringIO.new).workbook.worksheet(0)
      expect(sheet.row(0)).to eq(["Nombre rdv", "Service", "Département", "Mois"])
    end

    it "have a line for a RDV" do
      rdv = build(:rdv, created_at: Time.new(2020, 3, 23, 9, 54, 33))
      sheet = MonthlyStatsExporterService.new([rdv], StringIO.new).workbook.worksheet(0)
      expect(sheet.row(1)[0]).to eq(1)
      expect(sheet.row(1)[1]).to eq(rdv.motif.service.name)
      expect(sheet.row(1)[2]).to eq(rdv.organisation.departement)
      expect(sheet.row(1)[3]).to eq(rdv.starts_at.month.to_s)
    end
  end

  describe "#count_rdvs" do
    it "return empty hash with no Rdv" do
      exporter = MonthlyStatsExporterService.new([], StringIO.new)
      expect(exporter.count_rdv([])).to eq({})
    end

    it "return key with departement-motif-month and 1 as rdv number for one rdv " do
      exporter = MonthlyStatsExporterService.new([], StringIO.new)
      rdv = build(:rdv, created_at: Time.new(2020, 3, 23, 9, 54, 33))
      expect(exporter.count_rdv([rdv])).to eq({ "#{rdv.organisation.departement}-#{rdv.motif.service.name}-#{rdv.starts_at.month}" => 1 })
    end
  end
end
