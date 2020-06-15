class RdvExporterService < BaseService
  include XlsExporter

  def initialize(rdvs, file)
    @rdvs = rdvs
    @file = file
  end

  TYPE = { "user" => "Usager", "agent" => "Agent", "file_attente" => "File d'attente" }.freeze
  HourFormat = Spreadsheet::Format.new(number_format: 'hh:mm')
  DateFormat = Spreadsheet::Format.new(number_format: 'DD/MM/YYYY')

  def header
    ["date prise rdv", "heure prise rdv", "date rdv", "heure rdv", "motif", "pris par", "statut", "agents"].freeze
  end

  def build_lines(sheet)
    @rdvs.each_with_index do |rdv, index|
      row = sheet.row(index + 1)
      row.set_format 0, DateFormat
      row.set_format 1, HourFormat
      row.set_format 2, DateFormat
      row.set_format 3, HourFormat

      row.concat(row_array_from(rdv))
    end
  end

  def row_array_from(rdv)
    [
      rdv.created_at.to_date,
      rdv.created_at.to_time,
      rdv.starts_at.to_date,
      rdv.starts_at.to_time,
      rdv.motif.name,
      TYPE[rdv.created_by],
      ::Rdv.human_enum_name(:status, rdv.status),
      rdv.agents.map(&:full_name_and_service).join(", ")
    ]
  end
end
