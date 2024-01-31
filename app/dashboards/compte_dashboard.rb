require "administrate/base_dashboard"

class CompteDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    territory_name: Field::String,
  }

  COLLECTION_ATTRIBUTES = %i[
  ].freeze

  FORM_ATTRIBUTES = %i[territory_name]
end
