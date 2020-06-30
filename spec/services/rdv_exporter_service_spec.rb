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
      expect(sheet.row(0)).to eq(["année", "date prise rdv", "heure prise rdv", "date rdv", "heure rdv", "motif", "pris par", "statut", "lieu du rdv", "service", "agents"])
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
      expect(sheet.row(1)[8]).to eq(rdv.address)
      expect(sheet.row(1)[9]).to eq(rdv.motif.service.name)
      expect(sheet.row(1)[10]).to eq(rdv.agents.map(&:full_name).join(", "))
    end
  end

  it "return empty lieu when it's phone rdv" do
    motif = build(:motif, :by_phone)
    rdv = build(:rdv, created_at: Time.new(2020, 3, 23, 9, 54, 33), motif: motif, lieu: nil)
    sheet = RdvExporterService.new([rdv], StringIO.new).workbook.worksheet(0)
    expect(sheet.row(1)[8]).to eq("")
  end

  describe "#lieu" do
    it "return nothing for a phone rdv" do
      rdv = build(:rdv, :by_phone)
      exporter = RdvExporterService.new([rdv], StringIO.new)
      expect(exporter.lieu(rdv)).to eq("")
    end

    it "return mds address for a public_office rdv" do
      rdv = build(:rdv, motif: build(:motif, :at_public_office))
      exporter = RdvExporterService.new([rdv], StringIO.new)
      expect(exporter.lieu(rdv)).to eq(rdv.address)
    end

    # TODO: retourner la ville quand les adresses seront enregistrees plus proprement
    it "return only city for a at_home rdv"

    it "return nothing for a at_home rdv" do
      user = build(:user, address: "3 rue de l'églie 75020 Paris")
      rdv = build(:rdv, motif: build(:motif, :at_home), users: [user])
      exporter = RdvExporterService.new([rdv], StringIO.new)
      expect(exporter.lieu(rdv)).to eq("")
    end
  end
end
