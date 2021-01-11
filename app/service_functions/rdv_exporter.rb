module RdvExporter
  TYPE = { "user" => "Usager", "agent" => "Agent", "file_attente" => "File d'attente" }.freeze
  HourFormat = Spreadsheet::Format.new(number_format: "hh:mm")
  DateFormat = Spreadsheet::Format.new(number_format: "DD/MM/YYYY")
  HEADER = [
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
    "usager(s)",
    "au moins un usager mineur ?"
  ].freeze

  def self.export(rdvs)
    extract_string_from(build_excel_workbook_from(rdvs))
  end

  def self.extract_string_from(workbook)
    file = StringIO.new
    workbook.write(file)
    file.string
  end

  def self.build_excel_workbook_from(rdvs)
    Spreadsheet.client_encoding = "UTF-8"
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet
    sheet.row(0).concat(HEADER)

    rdvs.each_with_index do |rdv, index|
      row = sheet.row(index + 1)
      row.set_format 1, DateFormat
      row.set_format 2, HourFormat
      row.set_format 4, DateFormat
      row.set_format 5, HourFormat

      row.concat(row_array_from(rdv))
    end
    book
  end

  def self.row_array_from(rdv)
    [
      rdv.created_at.year,
      I18n.l(rdv.created_at.to_date),
      I18n.l(rdv.created_at.to_time, format: :time_only),
      origine(rdv),
      I18n.l(rdv.starts_at.to_date),
      I18n.l(rdv.starts_at.to_time, format: :time_only),
      rdv.motif.service.name,
      rdv.motif.name,
      rdv.context,
      I18n.t("activerecord.attributes.rdv.statuses.#{rdv.temporal_status}"),
      rdv.address_complete_without_personnal_details,
      rdv.agents.map(&:full_name).join(", "),
      rdv.users.map(&:full_name).join(", "),
      rdv.users.map(&:minor?).uniq.compact == [true] ? "oui" : "non"
    ]
  end

  def self.origine(rdv)
    rdv.created_by_user? ? "RDV Pris sur internet" : "Créé par un agent"
  end
end
