class ImportZoneRowsService < BaseService
  include DataUtils

  REQUIRED_FIELDS = ["sector_id", "city_name", "city_code"].freeze

  def initialize(rows, departement, agent, **options)
    @rows = rows
    @departement = departement
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
        errors: Hash.new(0)
      }
    }
    @result[:valid] = valid?
    @rows.each { import_row(_1) } if valid?
    @result
  end

  private

  def valid?
    @valid = compute_valid if @valid.nil? # avoid computing multiple times
    @valid
  end

  def compute_valid
    (
      validate_rows_present? &&
      validate_columns? &&
      validate_inner_conflicts? &&
      @rows.each_with_index.map do |row, row_index|
        validate_row_fields_present(row, row_index) &&
        validate_row_sector_found(row, row_index) &&
        validate_row_valid_zone(row, row_index) &&
        validate_row_authorized(row, row_index)
      end.all?
    )
  end

  def validate_rows_present?
    return true if @rows.any?

    @result[:errors] << "Aucune ligne"
    false
  end

  def validate_columns?
    missing_columns = REQUIRED_FIELDS - @rows.first.to_h.keys
    return true if missing_columns.empty?

    @result[:errors] << "Colonne(s) #{missing_columns.join(', ')} absente(s)"
    false
  end

  def validate_inner_conflicts?
    conflicts = value_counts(@rows.pluck("city_code")).to_a.filter { _2 > 1 }
    return true if conflicts.empty?

    conflicts.each do |city_code, count|
      @result[:errors] << "Le code commune #{city_code} apparaît #{count} fois"
    end
    false
  end

  def validate_row_fields_present(row, row_index)
    missing_fields = REQUIRED_FIELDS.filter { row[_1].blank? }
    return true if missing_fields.empty?

    @result[:row_errors][row_index] = "Champ(s) #{missing_fields.join(',')} manquant(s)"
    @result[:counts][:errors][:missing_fields] += 1
    false
  end

  def validate_row_sector_found(row, row_index)
    return true if find_sector(row["sector_id"]).present?

    @result[:row_errors][row_index] = "Aucun secteur trouvé pour l'identifiant #{row['sector_id']}"
    @result[:counts][:errors][:sector_not_found] += 1
    false
  end

  def validate_row_valid_zone(row, row_index)
    zone = build_zone(row)
    return true if zone.valid?

    @result[:row_errors][row_index] = zone.errors.full_messages.join(", ")
    @result[:counts][:errors]["invalid_zone_#{zone.errors.keys.first}".to_sym] += 1
    false
  end

  def validate_row_authorized(row, row_index)
    zone = build_zone(row)
    policy = Pundit.policy(AgentContext.new(@agent), [:agent, zone])
    return true if policy.create?

    @result[:row_errors][row_index] = "Pas les droits nécessaires pour créer une commune pour le secteur #{zone.sector_id}"
    @result[:counts][:errors][:unauthorized_zone] += 1
    false
  end

  def import_row(row)
    zone = build_zone(row)
    unless zone.valid?
      @messages[:error]
      @result[:counts][:errors][:invalid] += 1
      return
    end

    special_key = zone.new_record? ? :imported_new : :imported_override
    zone.save! unless @dry_run
    @result[:imported_zones] << zone
    @result[:counts][:imported][zone.sector.human_id] += 1
    @result[:counts][special_key][zone.sector.human_id] += 1
  end

  def build_zone(row)
    unique_attributes = { level: "city", city_code: row["city_code"] }
    extra_attributes = {
      sector: find_sector(row["sector_id"]),
      city_name: row["city_name"]
    }
    Zone.find_or_initialize_by(unique_attributes) # could be optimized
      .tap { _1.assign_attributes(extra_attributes) }
  end

  def find_sector(human_id)
    @sectors_cache ||= {}
    unless @sectors_cache.key?(human_id)
      @sectors_cache[human_id] = \
        Sector.find_by(departement: @departement, human_id: human_id)
    end
    @sectors_cache[human_id]
  end
end
