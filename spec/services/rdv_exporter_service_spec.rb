describe RdvExporterService, type: :service do
  it "build a workbook" do
    rdv_stat_builder = RdvExporterService.new([], StringIO.new)
    expect(rdv_stat_builder.workbook).to be_kind_of(Spreadsheet::Workbook)
  end

  it "have a work sheet in workbook" do
    rdv_stat_builder = RdvExporterService.new([], StringIO.new)
    expect(rdv_stat_builder.workbook.worksheet(0)).to be_kind_of(Spreadsheet::Worksheet)
  end

  context "with a sheet inside" do
    it "have an header" do
      sheet = RdvExporterService.new([], StringIO.new).workbook.worksheet(0)
      expect(sheet.row(0)).to eq(["année", "date prise rdv", "heure prise rdv", "date rdv", "heure rdv", "motif", "pris par", "statut", "lieux du rdv", "service", "agents"])
    end

    it "have a line for a RDV" do
      rdv = build(:rdv, created_at: Time.new(2020, 3, 23, 9, 54, 33))
      sheet = RdvExporterService.new([rdv], StringIO.new).workbook.worksheet(0)
      expect(sheet.row(1)[0]).to eq(rdv.created_at.year)
      expect(sheet.row(1)[1]).to eq(rdv.created_at.to_date)
      expect(sheet.row(1)[2].min).to eq(rdv.created_at.to_time.min)
      expect(sheet.row(1)[3]).to eq(rdv.starts_at.to_date)
      expect(sheet.row(1)[4].min).to eq(rdv.starts_at.to_time.min)
      expect(sheet.row(1)[5]).to eq(rdv.motif.name)
      expect(sheet.row(1)[6]).to eq("Agent")
      expect(sheet.row(1)[7]).to eq("Indéterminé")
      expect(sheet.row(1)[8]).to eq(rdv.lieu.full_name)
      expect(sheet.row(1)[9]).to eq(rdv.motif.service.name)
      expect(sheet.row(1)[10]).to eq(rdv.agents.map(&:full_name).join(", "))
    end
  end
end
