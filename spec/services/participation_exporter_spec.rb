RSpec.describe ParticipationExporter, type: :service do
  describe "#xls_string_from_rdvs_rows" do
    # rubocop:disable RSpec/ExampleLength
    it "return export with header" do
      rdv = create(
        :rdv,
        created_at: Time.zone.parse("2023-01-01 12h50"),
        starts_at: Time.zone.parse("2023-04-07 14h30"),
        status: :unknown,
        context: "des infos sur le rdv",
        lieu: create(:lieu, name: "MDS Paris Nord", address: "21 rue des Ardennes, Paris, 75019"),
        motif: build(:motif, name: "Consultation", service: build(:service, name: "PMI")),
        organisation: create(:organisation, name: "MDS Paris"),
        agents: [create(:agent, email: "agent@mail.com", first_name: "Francis", last_name: "Factice")],
        users: [create(:user, first_name: "Gaston", last_name: "Bidon", birth_date: Date.new(2000, 1, 1), address: nil)]
      )
      participation_row = described_class.row_array_from(rdv.participations.first)
      xls_string = described_class.xls_string_from_participations_rows([participation_row])

      header_row, first_data_row = Spreadsheet.open(StringIO.new(xls_string)).worksheets.first.rows

      # Les lettres sont les noms de colonnes Excel.
      # Il est important de toujours ajouter les nouvelles colonnes
      # à la fin pour ne pas gêner les SI des départements,
      # qui se basent parfois sur la position et non le libellé.
      expect(header_row).to contain_exactly("usager", "rdv_id", "année", "date prise rdv", "heure prise rdv", "origine", "date rdv", "heure rdv", "service", "motif", "contexte", "statut", "lieu", "professionnel.le(s)", "commune du responsable", "usager mineur ?", "résultat des notifications", "Organisation", "date naissance", "code postal du responsable", "créé par", "email(s) professionnel.le(s)")

      expect(first_data_row).to contain_exactly("Gaston BIDON", rdv.id, 2023, "01/01/2023", "12h50", "Créé par un agent", "07/04/2023", "14h30", "PMI", "Consultation", "des infos sur le rdv", "À renseigner", "MDS Paris Nord (21 rue des Ardennes, Paris, 75019)", "Francis FACTICE", nil, "non", nil, "MDS Paris", "01/01/2000", nil, "Dans le cadre du RGPD, cette information n'est plus conservée au delà d'un an.", "agent@mail.com")
    end
    # rubocop:enable RSpec/ExampleLength
  end

  describe "#row_array_from rdv" do
    describe "origine" do
      let(:agent) { create(:agent) }
      let(:user) { create(:user) }

      it "return « Créé par un agent » when rdv created by an agent" do
        rdv = build(:rdv, :with_fake_timestamps, created_by: agent)
        expect(described_class.row_array_from(rdv.participations.first)[5]).to eq("Créé par un agent")
      end

      it "return « RDV pris sur internet » when rdv taken by user" do
        rdv = build(:rdv, :with_fake_timestamps, created_by: user)
        expect(described_class.row_array_from(rdv.participations.first)[5]).to eq("RDV Pris sur internet")
      end
    end

    describe "lieu" do
      it "return « par Téléphone » when rdv by phone" do
        rdv = build(:rdv, :with_fake_timestamps, :by_phone)
        expect(described_class.row_array_from(rdv.participations.first)[12]).to eq("Par téléphone")
      end

      it "return « [domicile] adresse of user » when rdv is at home" do
        user = build(:user, address: "20 avenue de Ségur, Paris", first_name: "Lisa", last_name: "PAUL")
        rdv = build(:rdv, :with_fake_timestamps, :at_home, users: [user])
        expect(described_class.row_array_from(rdv.participations.first)[12]).to eq("À domicile")
      end

      it "return « lieu name and adresse » when rdv in place" do
        lieu = build(:lieu, name: "Centre ville", address: "3 place de la république, Hennebont, 56700")
        rdv = build(:rdv, :with_fake_timestamps, lieu: lieu)
        expect(described_class.row_array_from(rdv.participations.first)[12]).to eq("Centre ville (3 place de la république, Hennebont, 56700)")
      end
    end

    describe "professionnel.le(s)" do
      it "return all agent's names" do
        caro = build(:agent, first_name: "Caroline", last_name: "DUPUIS")
        karima = build(:agent, first_name: "Karima", last_name: "CHARNI")
        rdv = build(:rdv, :with_fake_timestamps, agents: [karima, caro])
        expect(described_class.row_array_from(rdv.participations.first)[13]).to eq("Karima CHARNI, Caroline DUPUIS")
      end
    end

    describe "commune du premier responsable" do
      it "return Châtillon when first responsable leave there" do
        first_major = create(:user, birth_date: Date.new(2002, 3, 12), city_name: "Châtillon")
        minor = create(:user, birth_date: Date.new(2016, 5, 30), responsible_id: first_major.id)
        other_major = create(:user, birth_date: Date.new(2002, 3, 12))
        other_minor = create(:user, birth_date: Date.new(2016, 5, 30), responsible_id: other_major.id)
        rdv = create(:rdv, created_at: Time.zone.local(2020, 3, 23, 9, 54, 33), users: [minor, other_minor, first_major, other_major])
        expect(described_class.row_array_from(rdv.participations.first)[14]).to eq("Châtillon")
      end

      it "return responsible's commune for relative" do
        first_major = create(:user, birth_date: Date.new(2002, 3, 12), city_name: "Châtillon")
        minor = create(:user, birth_date: Date.new(2016, 5, 30), responsible_id: first_major.id)
        rdv = create(:rdv, created_at: Time.zone.local(2020, 3, 23, 9, 54, 33), users: [minor])
        expect(described_class.row_array_from(rdv.participations.first)[14]).to eq("Châtillon")
      end
    end

    describe "un usager mineur ?" do
      it "return oui when one minor user" do
        now = Time.zone.parse("2020-4-3 13:45")
        travel_to(now)
        major = build(:user, birth_date: Date.new(2002, 3, 12))
        minor = build(:user, birth_date: Date.new(2016, 5, 30))
        rdv = build(:rdv, :with_fake_timestamps, created_at: Time.zone.local(2020, 3, 23, 9, 54, 33), users: [minor, major])
        expect(described_class.row_array_from(rdv.participations.first)[15]).to eq("oui")
        expect(described_class.row_array_from(rdv.participations.last)[15]).to eq("non")
      end
    end
  end

  describe "synthesized_receipts_result (résultat des notifications)" do
    it "return rdv synthesized_receipts_result" do
      rdv = build(:rdv, :with_fake_timestamps, starts_at: 1.day.ago)
      allow(rdv).to receive(:synthesized_receipts_result).and_return(:processed)
      expect(described_class.row_array_from(rdv.participations.first)[16]).to eq("Traité")
    end
  end

  describe "code postal du responsable" do
    it "return 92320 (Chatillon's postal code) when first responsable lives there" do
      major = create(:user, birth_date: Date.new(2002, 3, 12), address: "Rue Jean Jaurès, Châtillon, 92320")
      minor = create(:user, birth_date: Date.new(2016, 5, 30), responsible_id: major.id)
      rdv = create(:rdv, created_at: Time.zone.local(2020, 3, 23, 9, 54, 33), users: [minor, major])
      expect(described_class.row_array_from(rdv.participations.first)[19]).to eq("92320")
    end

    it "return responsible's postal code for relative" do
      major = create(:user, birth_date: Date.new(2002, 3, 12), address: "Rue Jean Jaurès, Châtillon, 92320")
      minor = create(:user, birth_date: Date.new(2016, 5, 30), responsible_id: major.id)
      rdv = create(:rdv, created_at: Time.zone.local(2020, 3, 23, 9, 54, 33), users: [minor])
      expect(described_class.row_array_from(rdv.participations.first)[19]).to eq("92320")
    end
  end

  describe "créé par" do
    let(:agent) { create(:agent) }

    it "return the agent name when rdv created by an agent" do
      rdv = create(:rdv, created_by: agent)
      rdv.versions.first.update!(whodunnit: "agent 008")
      expect(described_class.row_array_from(rdv.participations.first)[20]).to eq("agent 008")
    end
  end
end
