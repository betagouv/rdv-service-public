require "administrate/base_dashboard"

class CompteDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    territory_name: Field::String,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
  ].freeze

  FORM_ATTRIBUTES = %i[territory_name].freeze
end
