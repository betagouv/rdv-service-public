# frozen_string_literal: true

class ExportZonesService
  HEADER = %w[sector_name sector_id city_code city_name street_name street_code].freeze
  SQL_ORDER = "unaccent(LOWER(sectors.name)), unaccent(LOWER(city_name)), unaccent(LOWER(street_name))"

  def initialize(zones_arel)
    @zones_arel = zones_arel
  end

  def perform
    Spreadsheet.client_encoding = "UTF-8"
    workbook = Spreadsheet::Workbook.new
    sheet = workbook.create_worksheet
    sheet.row(0).concat(HEADER)
    zones_ordered.each_with_index { add_zone_row(sheet, _1, _2) }
    file = StringIO.new
    workbook.write(file)
    file.string
  end

  private

  def zones_ordered
    @zones_arel.includes(:sector).joins(:sector).order(Arel.sql(SQL_ORDER))
  end

  def add_zone_row(sheet, zone, index)
    row = sheet.row(index + 1)
    row.concat(
      [
        zone.sector.name,
        zone.sector.human_id,
        zone.city_code,
        zone.city_name,
        zone.street_name,
        zone.street_ban_id
      ]
    )
  end
end
