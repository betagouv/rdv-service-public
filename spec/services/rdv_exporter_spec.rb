# frozen_string_literal: true

describe RdvExporter, type: :service do
  describe "#export" do
    it "return a string" do
      expect(described_class.export(Rdv.none)).to be_kind_of(String)
    end
  end

  describe "#extract_string_from" do
    it "workbook return a string" do
      book = Spreadsheet::Workbook.new
      book.create_worksheet.row(0).concat([])
      expect(described_class.extract_string_from(book)).to be_kind_of(String)
    end
  end

  describe "#build_excel_workbook_from" do
    context "empty array" do
      it "return a Speadsheet::Workbook" do
        expect(described_class.build_excel_workbook_from(Rdv.none)).to be_kind_of(Spreadsheet::Workbook)
      end

      it "return an header" do
        sheet = described_class.build_excel_workbook_from(Rdv.none).worksheet(0)
        expect(sheet.row(0)).to eq(
          [
            "année",
            "date prise rdv",
            "heure prise rdv",
            "origine",
            "créé par",
            "date rdv",
            "heure rdv",
            "service",
            "motif",
            "contexte",
            "statut",
            "résultat des notifications",
            "lieu",
            "professionnel.le(s)",
            "usager(s)",
            "date naissance",
            "commune du premier responsable",
            "code postal du premier responsable",
            "au moins un usager mineur ?",
            "Organisation",
          ]
        )
      end
    end
  end

  describe "#row_array_from rdv" do
    describe "année" do
      it "return year of rdv creation" do
        rdv = build(:rdv, created_at: Time.zone.parse("2020-03-23 12h54"))
        expect(described_class.row_array_from(rdv)[0]).to eq(2020)
      end
    end

    describe "date prise de RDV" do
      it "return year of rdv creation" do
        rdv = build(:rdv, created_at: Time.zone.parse("2020-03-23 12h54"))
        expect(described_class.row_array_from(rdv)[1]).to eq("23/03/2020")
      end
    end

    describe "heure de prise de RDV" do
      it "return year of rdv creation" do
        rdv = build(:rdv, created_at: Time.zone.parse("2020-03-23 12h54"))
        expect(described_class.row_array_from(rdv)[2]).to eq("12h54")
      end
    end

    describe "origine" do
      it "return « Créé par un agent » when rdv created by an agent" do
        rdv = build(:rdv, created_by: :agent)
        expect(described_class.row_array_from(rdv)[3]).to eq("Créé par un agent")
      end

      it "return « RDV pris sur internet » when rdv taken by user" do
        rdv = build(:rdv, created_by: :user)
        expect(described_class.row_array_from(rdv)[3]).to eq("RDV Pris sur internet")
      end

      it "return « RDV en file d'attente? » when rdv created from file d'attente" do
        rdv = build(:rdv, created_by: :file_attente)
        expect(described_class.row_array_from(rdv)[3]).to eq("RDV en file d'attente")
      end
    end

    describe "créé par" do
      it "return the agent name when rdv created by an agent" do
        rdv = create(:rdv, created_by: :agent)
        rdv.versions.first.update!(whodunnit: "agent 008")
        expect(described_class.row_array_from(rdv)[4]).to eq("agent 008")
      end
    end

    describe "date" do
      it "return rdv Starts_at date, formatted with default" do
        rdv = build(:rdv, starts_at: Time.zone.parse("2020-12-07 12h50"))
        expect(described_class.row_array_from(rdv)[5]).to eq("07/12/2020")
      end
    end

    describe "heure rdv" do
      it "return rdv Starts_at time, formatted with time_only" do
        rdv = build(:rdv, starts_at: Time.zone.parse("2020-12-07 12h50"))
        expect(described_class.row_array_from(rdv)[6]).to eq("12h50")
      end
    end

    describe "service" do
      it "return rdv motif's service name" do
        rdv = build(:rdv, motif: build(:motif, service: build(:service, name: "PMI")))
        expect(described_class.row_array_from(rdv)[7]).to eq("PMI")
      end
    end

    describe "motif" do
      it "return rdv's motif name" do
        rdv = build(:rdv, motif: build(:motif, name: "Consultation"))
        expect(described_class.row_array_from(rdv)[8]).to eq("Consultation")
      end
    end

    describe "contexte" do
      it "return rdv's contexte" do
        rdv = build(:rdv, context: "en urgence")
        expect(described_class.row_array_from(rdv)[9]).to eq("en urgence")
      end
    end

    describe "statut" do
      it "return rdv statut" do
        rdv = build(:rdv, starts_at: 1.day.ago, status: "unknown")
        expect(described_class.row_array_from(rdv)[10]).to eq("À renseigner")
      end
    end

    describe "synthesized_receipts_result" do
      it "return rdv synthesized_receipts_result" do
        rdv = build(:rdv, starts_at: 1.day.ago)
        allow(rdv).to receive(:synthesized_receipts_result).and_return(:processed)
        expect(described_class.row_array_from(rdv)[11]).to eq("Traité")
      end
    end

    describe "lieu" do
      it "return « par Téléphone » when rdv by phone" do
        rdv = build(:rdv, :by_phone)
        expect(described_class.row_array_from(rdv)[12]).to eq("Par téléphone")
      end

      it "return « [domicile] adresse of user » when rdv is at home" do
        user = build(:user, address: "20 avenue de Ségur, Paris", first_name: "Lisa", last_name: "PAUL")
        rdv = build(:rdv, :at_home, users: [user])
        expect(described_class.row_array_from(rdv)[12]).to eq("À domicile")
      end

      it "return « lieu name and adresse » when rdv in place" do
        lieu = build(:lieu, name: "Centre ville", address: "3 place de la république 56700 Hennebont")
        rdv = build(:rdv, lieu: lieu)
        expect(described_class.row_array_from(rdv)[12]).to eq("Centre ville (3 place de la république 56700 Hennebont)")
      end
    end

    describe "professionnel.le(s)" do
      it "return all agent's names" do
        caro = build(:agent, first_name: "Caroline", last_name: "DUPUIS")
        karima = build(:agent, first_name: "Karima", last_name: "CHARNI")
        rdv = build(:rdv, agents: [karima, caro])
        expect(described_class.row_array_from(rdv)[13]).to eq("Karima CHARNI, Caroline DUPUIS")
      end
    end

    describe "usager(s)" do
      it "return all user's names" do
        ayoub = build(:user, first_name: "Ayoub", last_name: "PAUL")
        veronique = build(:user, first_name: "Véronique", last_name: "DIALO")
        rdv = build(:rdv, users: [veronique, ayoub])
        expect(described_class.row_array_from(rdv)[14]).to eq("Véronique DIALO, Ayoub PAUL")
      end
    end

    describe "date naissance" do
      it "return all user's birth dates" do
        ayoub = build(:user, first_name: "Ayoub", last_name: "PAUL")
        veronique = build(:user, first_name: "Véronique", last_name: "DIALO")
        rdv = build(:rdv, users: [veronique, ayoub])
        birth_dates = [veronique, ayoub].map(&:birth_date).map { |date| I18n.l(date) }.join(", ")
        expect(described_class.row_array_from(rdv)[15]).to eq(birth_dates)
      end
    end

    describe "commune du premier responsable" do
      it "return Châtillon when first responsable leave there" do
        first_major = create(:user, birth_date: Date.new(2002, 3, 12), city_name: "Châtillon")
        minor = create(:user, birth_date: Date.new(2016, 5, 30), responsible_id: first_major.id)
        other_major = create(:user, birth_date: Date.new(2002, 3, 12))
        other_minor = create(:user, birth_date: Date.new(2016, 5, 30), responsible_id: other_major.id)
        rdv = create(:rdv, created_at: Time.zone.local(2020, 3, 23, 9, 54, 33), users: [minor, other_minor, first_major, other_major])
        expect(described_class.row_array_from(rdv)[16]).to eq("Châtillon")
      end

      it "return responsible's commune for relative" do
        first_major = create(:user, birth_date: Date.new(2002, 3, 12), city_name: "Châtillon")
        minor = create(:user, birth_date: Date.new(2016, 5, 30), responsible_id: first_major.id)
        rdv = create(:rdv, created_at: Time.zone.local(2020, 3, 23, 9, 54, 33), users: [minor])
        expect(described_class.row_array_from(rdv)[16]).to eq("Châtillon")
      end

      it "return second responsible commune when first does not have one" do
        major = create(:user, birth_date: Date.new(2002, 3, 12), address: nil)
        minor = create(:user, birth_date: Date.new(2016, 5, 30), responsible_id: major.id)
        other_major = create(:user, birth_date: Date.new(2002, 3, 12), city_name: "Châtillon")
        other_minor = create(:user, birth_date: Date.new(2016, 5, 30), responsible_id: other_major.id)
        rdv = create(:rdv, created_at: Time.zone.local(2020, 3, 23, 9, 54, 33), users: [minor, other_minor, major, other_major])
        expect(described_class.row_array_from(rdv)[16]).to eq("Châtillon")
      end
    end

    describe "code postal du premier responsable" do
      it "return 92320 (Chatillon's postal code) when first responsable leave there" do
        first_major = create(:user, birth_date: Date.new(2002, 3, 12), address: "Rue Jean Jaurès, 92320 Châtillon")
        minor = create(:user, birth_date: Date.new(2016, 5, 30), responsible_id: first_major.id)
        other_major = create(:user, birth_date: Date.new(2002, 3, 12))
        other_minor = create(:user, birth_date: Date.new(2016, 5, 30), responsible_id: other_major.id)
        rdv = create(:rdv, created_at: Time.zone.local(2020, 3, 23, 9, 54, 33), users: [minor, other_minor, first_major, other_major])
        expect(described_class.row_array_from(rdv)[17]).to eq("92320")
      end

      it "return responsible's postal code for relative" do
        first_major = create(:user, birth_date: Date.new(2002, 3, 12), address: "Rue Jean Jaurès, 92320 Châtillon")
        minor = create(:user, birth_date: Date.new(2016, 5, 30), responsible_id: first_major.id)
        rdv = create(:rdv, created_at: Time.zone.local(2020, 3, 23, 9, 54, 33), users: [minor])
        expect(described_class.row_array_from(rdv)[17]).to eq("92320")
      end

      it "return second responsible postal code when first does not have one" do
        major = create(:user, birth_date: Date.new(2002, 3, 12), address: nil)
        minor = create(:user, birth_date: Date.new(2016, 5, 30), responsible_id: major.id)
        other_major = create(:user, birth_date: Date.new(2002, 3, 12), address: "Rue Jean Jaurès, 92320 Châtillon")
        other_minor = create(:user, birth_date: Date.new(2016, 5, 30), responsible_id: other_major.id)
        rdv = create(:rdv, created_at: Time.zone.local(2020, 3, 23, 9, 54, 33), users: [minor, other_minor, major, other_major])
        expect(described_class.row_array_from(rdv)[17]).to eq("92320")
      end
    end

    describe "un usager mineur ?" do
      it "return oui when one minor user" do
        now = Time.zone.parse("2020-4-3 13:45")
        travel_to(now)
        major = build(:user, birth_date: Date.new(2002, 3, 12))
        minor = build(:user, birth_date: Date.new(2016, 5, 30))
        rdv = build(:rdv, created_at: Time.zone.local(2020, 3, 23, 9, 54, 33), users: [minor, major])
        expect(described_class.row_array_from(rdv)[18]).to eq("oui")
      end
    end
  end

  describe "contient l'organisation courante" do
    it "return organisation name" do
      organisation = build(:organisation, name: "CMS du Brusc")
      rdv = build(:rdv, organisation: organisation)
      expect(described_class.row_array_from(rdv)[19]).to eq("CMS du Brusc")
    end
  end
end
