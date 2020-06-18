class ZoneForm
  include ActiveModel::Model

  attr_reader :zone, :city_label

  delegate :organisation, :organisation_id, :level, :city_name, :city_code, :errors, :save, :persisted?, to: :zone

  def initialize(zone, **attributes)
    @zone = zone
    attributes = attributes.with_indifferent_access
    @city_label = attributes[:city_label]
    @zone.update_attributes(**attributes.except(:city_label)) if attributes.present?
  end
end
