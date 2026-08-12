RSpec.describe ExportSendEmailJob do
  describe ".write_xls_to_io" do
    it "return participations export with header" do
      organisation = create(:organisation, name: "MDS Paris")
      lieu = create(:lieu, name: "MDS Paris Nord", address: "21 rue des Ardennes, Paris, 75019", organisation:)
      motif = build(:motif, name: "Consultation", service: build(:service, name: "PMI"), organisation:)
      rdv = create(
        :rdv,
        created_at: Time.zone.parse("2023-01-01 12h50"),
        starts_at: Time.zone.parse("2023-04-07 14h30"),
        status: :unknown,
        context: "des infos sur le rdv",
        lieu:,
        motif:,
        organisation:,
        agents: [create(:agent, email: "agent@mail.com", first_name: "Francis", last_name: "Factice")],
        users: [create(:user, first_name: "Gaston", last_name: "Bidon", birth_date: Date.new(2000, 1, 1), address: nil)]
      )
      participation_row = described_class.row_array_from(rdv.participations.first)
      io = StringIO.new
      described_class.write_xls_to_io(io, [participation_row], Export::PARTICIPATIONS_EXPORT)

      header_row, first_data_row = Spreadsheet.open(io).worksheets.first.rows

      # Les lettres sont les noms de colonnes Excel.
      # Il est important de toujours ajouter les nouvelles colonnes
      # à la fin pour ne pas gêner les SI des départements,
      # qui se basent parfois sur la position et non le libellé.
      expect(header_row).to eq(
        [
          "usager",
          "rdv_id",
          "année",
          "date prise rdv",
          "heure prise rdv",
          "origine",
          "date rdv",
          "heure rdv",
          "service",
          "motif",
          "contexte",
          "statut",
          "lieu",
          "professionnel.le(s)",
          "commune du responsable",
          "usager mineur ?",
          "résultat des notifications",
          "Organisation",
          "date naissance",
          "code postal du responsable",
          "créé par",
          "email(s) professionnel.le(s)",
          "rdv collectif",
          "inscription au rdv collectif par",
        ]
      )

      expect(first_data_row).to eq(
        [
          "Gaston BIDON",
          rdv.id,
          2023, "01/01/2023", "12h50",
          "Créé par un agent",
          "07/04/2023", "14h30",
          "PMI",
          "Consultation",
          "des infos sur le rdv",
          "À renseigner",
          "MDS Paris Nord (21 rue des Ardennes, Paris, 75019)",
          "Francis FACTICE",
          nil,
          "non",
          nil,
          "MDS Paris",
          "01/01/2000",
          nil,
          "Dans le cadre du RGPD, cette information n'est plus conservée au delà d'un an.",
          "agent@mail.com",
          "non",
          nil,
        ]
      )
    end
  end

  it "return rdvs export with header" do
    rdv = create(:rdv, created_at: Time.zone.parse("2023-01-01"), agents: [create(:agent, email: "agent@mail.com")])
    rdv_row = described_class.row_array_from(rdv)
    io = StringIO.new
    described_class.write_xls_to_io(io, [rdv_row], Export::RDV_EXPORT)

    header_row, first_data_row = Spreadsheet.open(io).worksheets.first.rows

    # Les lettres sont les noms de colonnes Excel.
    # Il est important de toujours ajouter les nouvelles colonnes
    # à la fin pour ne pas gêner les SI des départements,
    # qui se basent parfois sur la position et non le libellé.
    expect(header_row).to eq(
      [
        "année", # A
        "date prise rdv", # B
        "heure prise rdv", # C
        "origine", # D
        "date rdv", # E
        "heure rdv", # F
        "service", # G
        "motif", # H
        "contexte", # I
        "statut", # J
        "lieu", # K
        "professionnel.le(s)", # L
        "usager(s)", # M
        "commune du premier responsable", # N
        "au moins un usager mineur ?", # O
        "résultat des notifications", # P
        "Organisation", # Q
        "date naissance", # R
        "code postal du premier responsable", # S
        "créé par", # T
        "email(s) professionnel.le(s)", # U
        "rdv collectif", # V
      ]
    )

    expect(first_data_row.first).to eq(2023)
    expect(first_data_row.last).to eq("non")
  end
end
