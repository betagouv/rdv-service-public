class ImportZoneRowsService < BaseService
  include DataUtils

  REQUIRED_FIELDS = {
    Zone::LEVEL_CITY => %w[sector_id city_name city_code],
    Zone::LEVEL_STREET => %w[sector_id city_name city_code street_name street_code],
  }.freeze

  def initialize(rows, territory, agent, **options)
    @rows = rows
    @territory = territory
    @agent = agent
    @dry_run = options.fetch(:dry_run, false)
  end

  def perform
    @result = {
      errors: [],
      row_errors: {},
      imported_zones: [],
      counts: {
        imported: Hash.new(0),
        imported_new: Hash.new(0),
        imported_override: Hash.new(0),
        errors: Hash.new(0),
      },
    }
    @result[:valid] = valid?
    @rows.each { import_row(_1) } if valid?
    @result
  end

  private

  def valid?
    return @valid unless @valid.nil? # avoid computing multiple times

    @valid =
      validate_rows_present? &&
      validate_columns? &&
      validate_inner_conflicts_cities? &&
      validate_inner_conflicts_streets? &&
      @rows.each_with_index.map { |row, row_index| valid_row?(row, row_index) }.all?
  end

  def validate_rows_present?
    return true if @rows.any?

    @result[:errors] << "Aucune ligne"
    false
  end

  def validate_columns?
    missing_columns = REQUIRED_FIELDS[Zone::LEVEL_CITY] - @rows.first.to_h.keys
    return true if missing_columns.empty?

    @result[:errors] << "Colonne(s) #{missing_columns.join(', ')} absente(s)"
    false
  end

  def validate_inner_conflicts_cities?
    conflicts = value_counts(rows_cities.pluck("city_code")).filter { |_city_code, count| count > 1 }
    return true if conflicts.empty?

    conflicts.each do |city_code, count|
      @result[:errors] << "Le code commune #{city_code} apparaît #{count} fois"
    end
    false
  end

  def validate_inner_conflicts_streets?
    conflicts = value_counts(rows_streets.pluck("street_code")).filter { |_street_ban_id, count| count > 1 }
    return true if conflicts.empty?

    conflicts.each do |street_ban_id, count|
      @result[:errors] << "Le code rue #{street_ban_id} apparaît #{count} fois"
    end
    false
  end

  def valid_row?(row, row_index)
    zone_import_row = zone_import_row_for(row)
    return true if zone_import_row.valid?

    zone_import_row.errors.each do |error|
      @result[:row_errors][row_index] = error[:message]
      @result[:counts][:errors][error[:key]] += 1
    end
    false
  end

  def import_row(row)
    row_import_result = zone_import_row_for(row).import
    unless row_import_result.imported?
      @result[:counts][:errors][:invalid] += 1
      return
    end

    @result[:imported_zones] << row_import_result.zone
    @result[:counts][:imported][row_import_result.zone.sector.human_id] += 1
    @result[:counts][row_import_result.key][row_import_result.zone.sector.human_id] += 1
  end

  def sectors_by_human_id
    @sectors_by_human_id ||= Sector
      .where(territory: @territory, human_id: @rows.pluck("sector_id"))
      .map { [_1.human_id, _1] }
      .to_h
  end

  def zone_import_row_for(row)
    ZoneImportRow.new(
      row,
      agent: @agent,
      dry_run: @dry_run,
      sectors_by_human_id: sectors_by_human_id
    )
  end

  def rows_cities
    @rows_cities ||= @rows.select { row_level(_1) == Zone::LEVEL_CITY }
  end

  def rows_streets
    @rows_streets ||= @rows.select { row_level(_1) == Zone::LEVEL_STREET }
  end

  def row_level(row)
    row["street_name"].present? || row["street_code"].present? ? Zone::LEVEL_STREET : Zone::LEVEL_CITY
  end
end
