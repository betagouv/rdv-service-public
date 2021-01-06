describe RdvExporter, type: :service do
  describe "#export" do
    it "return a string" do
      expect(RdvExporter.export([])).to be_kind_of(String)
    end
  end

  describe "#extract_string_from" do
    it "workbook return a string" do
      book = Spreadsheet::Workbook.new
      book.create_worksheet.row(0).concat([])
      expect(RdvExporter.extract_string_from(book)).to be_kind_of(String)
    end
  end

  describe "#build_excel_workbook_from" do
    context "empty array" do
      it "return a Speadsheet::Workbook" do
        expect(RdvExporter.build_excel_workbook_from([])).to be_kind_of(Spreadsheet::Workbook)
      end

      it "return an header" do
        sheet = RdvExporter.build_excel_workbook_from([]).worksheet(0)
        expect(sheet.row(0)).to eq(["origine", "date rdv", "heure rdv", "motif", "contexte", "lieu", "professionnel.le(s)", "usager(s)", "statut"])
      end
    end
  end

  describe "#row_array_from rdv" do
    describe "origine" do
      it "return « Créé par un agent » when rdv created by an agent" do
        rdv = build(:rdv)
        expect(RdvExporter.row_array_from(rdv)[0]).to eq("Créé par un agent")
      end

      it "return « RDV pris sur internet » when rdv taken by user" do
        rdv = build(:rdv, created_by: Rdv.created_bies[:user])
        expect(RdvExporter.row_array_from(rdv)[0]).to eq("RDV Pris sur internet")
      end

      it "return « RDV en file d'attente? » when rdv created from file d'attente"
    end

    describe "date" do
      it "return rdv Starts_at date, formatted with default" do
        rdv = build(:rdv, starts_at: Time.zone.parse("2020-12-07 12h50"))
        expect(RdvExporter.row_array_from(rdv)[1]).to eq("07/12/2020")
      end
    end

    describe "heure rdv" do
      it "return rdv Starts_at time, formatted with time_only" do
        rdv = build(:rdv, starts_at: Time.zone.parse("2020-12-07 12h50"))
        expect(RdvExporter.row_array_from(rdv)[2]).to eq("12h50")
      end
    end

    describe "motif" do
      it "return rdv's motif name" do
        rdv = build(:rdv, motif: build(:motif, name: "Consultation"))
        expect(RdvExporter.row_array_from(rdv)[3]).to eq("Consultation")
      end
    end

    describe "contexte" do
      it "return rdv's contexte" do
        rdv = build(:rdv, context: "en urgence")
        expect(RdvExporter.row_array_from(rdv)[4]).to eq("en urgence")
      end
    end

    describe "lieu" do
      it "return « par Téléphone » when rdv by phone" do
        rdv = build(:rdv, :by_phone)
        expect(RdvExporter.row_array_from(rdv)[5]).to eq("Par téléphone")
      end

      it "return « [domicile] adresse of user » when rdv is at home" do
        user = build(:user, address: "20 avenue de Ségur, Paris", first_name: "Lisa", last_name: "PAUL")
        rdv = build(:rdv, :at_home, users: [user])
        expect(RdvExporter.row_array_from(rdv)[5]).to eq("À domicile")
      end

      it "return « lieu name and adresse » when rdv in place" do
        lieu = build(:lieu, name: "Centre ville", address: "3 place de la république 56700 Hennebont")
        rdv = build(:rdv, lieu: lieu)
        expect(RdvExporter.row_array_from(rdv)[5]).to eq("Centre ville (3 place de la république 56700 Hennebont)")
      end
    end

    describe "professionnel.le(s)" do
      it "return all agent's names" do
        caro = build(:agent, first_name: "Caroline", last_name: "DUPUIS")
        karima = build(:agent, first_name: "Karima", last_name: "CHARNI")
        rdv = build(:rdv, agents: [karima, caro])
        expect(RdvExporter.row_array_from(rdv)[6]).to eq("Karima CHARNI, Caroline DUPUIS")
      end
    end

    describe "usager(s)" do
      it "return all user's names" do
        ayoub = build(:user, first_name: "Ayoub", last_name: "PAUL")
        veronique = build(:user, first_name: "Véronique", last_name: "DIALO")
        rdv = build(:rdv, users: [veronique, ayoub])
        expect(RdvExporter.row_array_from(rdv)[7]).to eq("Véronique DIALO, Ayoub PAUL")
      end
    end

    describe "statut" do
      it "return rdv statut" do
        rdv = build(:rdv, :past, status: "unknown")
        expect(RdvExporter.row_array_from(rdv)[8]).to eq("À renseigner")
      end
    end
  end
end
