module StatRdvExporter
  TYPE = { "user" => "Usager", "agent" => "Agent", "file_attente" => "File d'attente" }.freeze
  HourFormat = Spreadsheet::Format.new(number_format: "hh:mm")
  DateFormat = Spreadsheet::Format.new(number_format: "DD/MM/YYYY")
  HEADER = [
    "année",
    "date prise rdv",
    "heure prise rdv",
    "date rdv",
    "heure rdv",
    "usager mineur/majeur",
    "motif",
    "pris par",
    "statut",
    "lieu du rdv",
    "agents"
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
      row.set_format 3, DateFormat
      row.set_format 4, HourFormat

      row.concat(row_array_from(rdv))
    end
    book
  end

  def self.row_array_from(rdv)
    [
      rdv.created_at.year,
      rdv.created_at.to_date,
      rdv.created_at.to_time,
      rdv.starts_at.to_date,
      rdv.starts_at.to_time,
      majeur_ou_mineur(rdv),
      rdv.motif.name,
      TYPE[rdv.created_by],
      ::Rdv.human_enum_name(:status, rdv.status),
      rdv.address_complete_without_personnal_details,
      rdv.motif.service.name,
      rdv.agents.map(&:full_name).join(", ")
    ]
  end

  def self.majeur_ou_mineur(rdv)
    return "n/a" if rdv.users.map(&:birth_date).uniq.compact.empty?

    rdv.users.select{ _1.mineur? }.any? ? "mineur" : "majeur"
  end
end
