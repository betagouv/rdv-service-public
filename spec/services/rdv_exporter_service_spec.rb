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
      expect(sheet.row(0)).to eq(["année", "date prise rdv", "heure prise rdv", "date rdv", "heure rdv", "usager mineur/majeur", "motif", "pris par", "statut", "lieu du rdv", "service", "agents"])
    end

    it "have a line for a RDV" do
      rdv = build(:rdv, created_at: Time.new(2020, 3, 23, 9, 54, 33))
      sheet = RdvExporterService.new([rdv], StringIO.new).workbook.worksheet(0)
      expect(sheet.row(1)[0]).to eq(2020)
      expect(sheet.row(1)[1]).to eq(rdv.created_at.to_date)
      expect(sheet.row(1)[2].min).to eq(rdv.created_at.to_time.min)
      expect(sheet.row(1)[3]).to eq(rdv.starts_at.to_date)
      expect(sheet.row(1)[4].min).to eq(rdv.starts_at.to_time.min)
      expect(sheet.row(1)[5]).to eq("majeur")
      expect(sheet.row(1)[6]).to eq(rdv.motif.name)
      expect(sheet.row(1)[7]).to eq("Agent")
      expect(sheet.row(1)[8]).to eq("Indéterminé")
      expect(sheet.row(1)[9]).to eq(rdv.address_complete_without_personnal_details)
      expect(sheet.row(1)[10]).to eq(rdv.motif.service.name)
      expect(sheet.row(1)[11]).to eq(rdv.agents.map(&:full_name).join(", "))
    end
  end

  it "return empty lieu when it's phone rdv" do
    motif = build(:motif, :by_phone)
    rdv = build(:rdv, created_at: Time.new(2020, 3, 23, 9, 54, 33), motif: motif, lieu: nil)
    sheet = RdvExporterService.new([rdv], StringIO.new).workbook.worksheet(0)
    expect(sheet.row(1)[9]).to eq("Par téléphone")
  end

  describe "#mineur_ou_majeur" do
    it "return mineur when rdv's user is minor" do
      now = Time.zone.parse("2020-4-3 13:45")
      travel_to(now)
      user = build(:user, birth_date: Date.new(2016, 5, 30))
      rdv = build(:rdv, created_at: Time.new(2020, 3, 23, 9, 54, 33), users: [user])
      exporter = RdvExporterService.new([rdv], StringIO.new)
      expect(exporter.majeur_ou_mineur(rdv)).to eq("mineur")
    end

    it "return mineur when only one of rdv's user is minor" do
      now = Time.zone.parse("2020-4-3 13:45")
      travel_to(now)
      minor_user = build(:user, birth_date: Date.new(2000, 10, 4))
      major_user = build(:user, birth_date: Date.new(2016, 5, 30))
      rdv = build(:rdv, created_at: Time.new(2020, 3, 23, 9, 54, 33), users: [major_user, minor_user])
      exporter = RdvExporterService.new([rdv], StringIO.new)
      expect(exporter.majeur_ou_mineur(rdv)).to eq("mineur")
    end
  end
end
