# frozen_string_literal: true

class ZoneSearchForm
  include ActiveModel::Model

  attr_accessor :level, :city, :orga_id

  # organisation_id fails because it conflicts with a pundit param

  def filter_zones(arel = Zone.all)
    if city.present?
      arel = arel.where("city_name ILIKE '%#{city}%'")
        .or(arel.where("city_code ILIKE '%#{city}%'"))
    end
    arel = arel.where(organisation_id: orga_id) if orga_id.present?
    arel
  end

  def to_query
    { level: level, city: city, organisation_id: orga_id }
  end
end
