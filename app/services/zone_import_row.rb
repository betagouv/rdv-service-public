class ZoneImportRow
  attr_accessor :errors

  REQUIRED_FIELDS = {
    Zone::LEVEL_CITY => %w[sector_id city_name city_code],
    Zone::LEVEL_STREET => %w[sector_id city_name city_code street_name street_code],
  }.freeze

  def initialize(row, agent:, dry_run:, sectors_by_human_id:)
    @row = row
    @agent = agent
    @dry_run = dry_run
    @sectors_by_human_id = sectors_by_human_id
  end

  def validate
    return if @validated

    @errors = []
    fields_present?
    sector_found?
    valid_zone?
    authorized?
    @validated = true
  end

  def valid?
    validate
    @errors.empty?
  end

  def import
    rebuilt_zone = build_zone # important to rebuild right before saving
    return OpenStruct.new(imported?: false) unless rebuilt_zone.valid?

    key = rebuilt_zone.new_record? ? :imported_new : :imported_override
    rebuilt_zone.save! unless @dry_run
    OpenStruct.new(imported?: true, key: key, zone: rebuilt_zone)
  end

  private

  def fields_present?
    missing_fields = REQUIRED_FIELDS[zone_level].filter { @row[_1].blank? }
    return true if missing_fields.empty?

    @errors << { key: :missing_fields, message: "Champ(s) #{missing_fields.join(',')} manquant(s)" }
    false
  end

  def sector_found?
    return true if !fields_present? || @sectors_by_human_id[@row["sector_id"]].present?

    @errors << { key: :sector_not_found, message: "Aucun secteur trouvé pour l'identifiant #{@row['sector_id']}" }
    false
  end

  def valid_zone?
    return true if !fields_present? || !sector_found? || zone.valid?

    @errors << {
      key: :"invalid_zone_#{zone.errors.attribute_names.first}",
      message: zone.errors.full_messages.join(", "),
    }
    false
  end

  def authorized?
    return true if !fields_present? || !sector_found? || !valid_zone?

    policy = Agent::ZonePolicy.new(@agent, zone)
    return true if policy.create?

    @errors << {
      key: :unauthorized_zone,
      message: "Pas les droits nécessaires pour ajouter une commune ou une rue au secteur #{zone.sector_id}",
    }
    false
  end

  def zone_level
    @row["street_name"].present? || @row["street_code"].present? ? Zone::LEVEL_STREET : Zone::LEVEL_CITY
  end

  def zone
    @zone ||= build_zone
  end

  def build_zone
    unique_attributes = {
      level: zone_level,
      city_code: @row["city_code"],
      sector: @sectors_by_human_id[@row["sector_id"]],
    }
    unique_attributes[:street_ban_id] = @row["street_code"] if zone_level == Zone::LEVEL_STREET
    extra_attributes = { city_name: @row["city_name"], street_name: @row["street_name"] }
    Zone.find_or_initialize_by(unique_attributes) # could be optimized
      .tap { _1.assign_attributes(extra_attributes) }
  end
end
