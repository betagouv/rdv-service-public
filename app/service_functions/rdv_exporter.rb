module RdvExporter
  TYPE = { "user" => "Usager", "agent" => "Agent", "file_attente" => "File d'attente" }.freeze
  HourFormat = Spreadsheet::Format.new(number_format: "hh:mm")
  DateFormat = Spreadsheet::Format.new(number_format: "DD/MM/YYYY")
  HEADER = [
    "origine",
    "date rdv",
    "heure rdv",
    "motif",
    "contexte",
    "lieu",
    "professionnel.le(s)",
    "usager(s)",
    "statut",
  ].freeze

  def self.export(rdvs, file)
    Spreadsheet.client_encoding = "UTF-8"
    build_workbook(rdvs).write(file)
    file.string
  end

  def self.build_workbook(rdvs)
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet
    sheet.row(0).concat(HEADER)

    rdvs.each_with_index do |rdv, index|
      row = sheet.row(index + 1)
      row.set_format 2, DateFormat
      row.set_format 3, HourFormat

      row.concat(row_array_from(rdv))
    end
    book
  end

  def self.row_array_from(rdv)
    [
      origine(rdv),
      I18n.l(rdv.starts_at.to_date),
      I18n.l(rdv.starts_at.to_time, format: :time_only),
      rdv.motif.name,
      rdv.context,
      lieu(rdv),
      rdv.agents.map(&:full_name).join(", "),
      rdv.users.map(&:full_name).join(", "),
      I18n.t("activerecord.attributes.rdv.statuses.#{rdv.temporal_status}")
    ]
  end

  def self.origine(rdv)
    rdv.created_by_user? ? "RDV Pris sur internet" : "Créé par un agent"
  end

  def self.lieu(rdv)
    if rdv.phone?
      "RDV téléphonique"
    elsif rdv.home?
      "RDV à domicile : #{rdv.address_complete}"
    elsif rdv.public_office?
      rdv.address_complete
    else
      ""
    end
  end
end
