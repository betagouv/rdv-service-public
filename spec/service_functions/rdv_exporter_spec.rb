describe RdvExporter, type: :service do
  it "return a string" do
    expect(RdvExporter.export([], StringIO.new)).to be_kind_of(String)
  end

  it "build a workbook" do
    expect(RdvExporter.build_workbook([])).to be_kind_of(Spreadsheet::Workbook)
  end

  context "with a worksheet inside," do
    it "have an header" do
      sheet = RdvExporter.build_workbook([]).worksheet(0)
      expect(sheet.row(0)).to eq(["origine", "date rdv", "heure rdv", "motif", "contexte", "lieu", "professionnel.le(s)", "usager(s)", "statut"])
    end

    describe "origine" do
      it "return « Créé par un agent » when rdv created by an agent" do
        rdv = build(:rdv)
        sheet = RdvExporter.build_workbook([rdv]).worksheet(0)
        expect(sheet.row(1)[0]).to eq("Créé par un agent")
      end

      it "return « RDV pris sur internet » when rdv taken by user" do
        rdv = build(:rdv, created_by: Rdv.created_bies[:user])
        sheet = RdvExporter.build_workbook([rdv]).worksheet(0)
        expect(sheet.row(1)[0]).to eq("RDV Pris sur internet")
      end

      it "return « RDV en file d'attente? » when rdv created from file d'attente"
    end

    describe "date rdv" do
      it "return rdv Starts_at date, formatted with default" do
        rdv = build(:rdv, starts_at: Time.zone.parse("2020-12-07 12h50"))
        sheet = RdvExporter.build_workbook([rdv]).worksheet(0)
        expect(sheet.row(1)[1]).to eq("07/12/2020")
      end
    end

    describe "heure rdv" do
      it "return rdv Starts_at time, formatted with time_only" do
        rdv = build(:rdv, starts_at: Time.zone.parse("2020-12-07 12h50"))
        sheet = RdvExporter.build_workbook([rdv]).worksheet(0)
        expect(sheet.row(1)[2]).to eq("12h50")
      end
    end

    describe "motif" do
      it "return rdv's motif name" do
        rdv = build(:rdv, motif: build(:motif, name: "Consultation"))
        sheet = RdvExporter.build_workbook([rdv]).worksheet(0)
        expect(sheet.row(1)[3]).to eq("Consultation")
      end
    end

    describe "contexte" do
      it "return rdv's contexte" do
        rdv = build(:rdv, context: "en urgence")
        sheet = RdvExporter.build_workbook([rdv]).worksheet(0)
        expect(sheet.row(1)[4]).to eq("en urgence")
      end
    end

    describe "lieu" do
      it "return « par Téléphone » when rdv by phone" do
        rdv = build(:rdv, :by_phone)
        sheet = RdvExporter.build_workbook([rdv]).worksheet(0)
        expect(sheet.row(1)[5]).to eq("RDV téléphonique")
      end

      it "return « [domicile] adresse of user » when rdv is at home" do
        user = build(:user, address: "20 avenue de Ségur, Paris", first_name: "Lisa", last_name: "PAUL")
        rdv = build(:rdv, :at_home, users: [user])
        sheet = RdvExporter.build_workbook([rdv]).worksheet(0)
        expect(sheet.row(1)[5]).to eq("RDV à domicile : Adresse de Lisa PAUL - 20 avenue de Ségur, Paris")
      end

      it "return « lieu name and adresse » when rdv in place" do
        lieu = build(:lieu, name: "Centre ville", address: "3 place de la république 56700 Hennebont")
        rdv = build(:rdv, lieu: lieu)
        sheet = RdvExporter.build_workbook([rdv]).worksheet(0)
        expect(sheet.row(1)[5]).to eq("Centre ville (3 place de la république 56700 Hennebont)")
      end
    end

    describe "professionnel.le(s)" do
      it "return all agent's names" do
        caro = build(:agent, first_name: "Caroline", last_name: "DUPUIS")
        karima = build(:agent, first_name: "Karima", last_name: "CHARNI")
        rdv = build(:rdv, agents: [karima, caro])
        sheet = RdvExporter.build_workbook([rdv]).worksheet(0)
        expect(sheet.row(1)[6]).to eq("Karima CHARNI, Caroline DUPUIS")
      end
    end

    it "return mineur when only one of rdv's user is minor" do
      now = Time.zone.parse("2020-4-3 13:45")
      travel_to(now)
      major_user = build(:user, birth_date: Date.new(2000, 10, 4))
      minor_user = build(:user, birth_date: Date.new(2016, 5, 30))
      rdv = build(:rdv, created_at: Time.new(2020, 3, 23, 9, 54, 33), users: [major_user, minor_user])
      expect(RdvExporter.majeur_ou_mineur(rdv)).to eq("mineur")
    end

    describe "usager(s)" do
      it "return all user's names" do
        ayoub = build(:user, first_name: "Ayoub", last_name: "PAUL")
        veronique = build(:user, first_name: "Véronique", last_name: "DIALO")
        rdv = build(:rdv, users: [veronique, ayoub])
        sheet = RdvExporter.build_workbook([rdv]).worksheet(0)
        expect(sheet.row(1)[7]).to eq("Véronique DIALO, Ayoub PAUL")
      end
    end

    describe "statut" do
      it "return rdv statut" do
        rdv = build(:rdv, :past, status: "unknown")
        sheet = RdvExporter.build_workbook([rdv]).worksheet(0)
        expect(sheet.row(1)[8]).to eq("À renseigner")
      end
    end

    it "return mineur if the user with a birthdate is minor" do
      now = Time.zone.parse("2020-4-3 13:45")
      travel_to(now)
      user = build(:user, birth_date: "")
      minor_user = build(:user, birth_date: Date.new(2016, 5, 30))
      rdv = build(:rdv, created_at: Time.new(2020, 3, 23, 9, 54, 33), users: [user, minor_user])
      expect(RdvExporter.majeur_ou_mineur(rdv)).to eq("mineur")
    end
  end
end
