class ZoneSearchForm
  include ActiveModel::Model

  attr_accessor :level, :city, :organisation_id

  def filter_zones(arel = Zone.all)
    if city.present?
      arel = arel.where("city_name ILIKE '%#{city}%'")
        .or(arel.where("city_code ILIKE '%#{city}%'"))
    end
    arel = arel.where(organisation_id: organisation_id) if organisation_id.present?
    arel
  end

  def to_query
    { level: level, city: city, organisation_id: organisation_id }
  end
end
