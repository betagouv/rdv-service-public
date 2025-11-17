require "administrate/base_dashboard"

class OperatorDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    territories: Field::HasMany,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    name
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    territories
  ].freeze

  FORM_ATTRIBUTES = %i[
    name
  ].freeze

  def display_resource(operator)
    operator.name
  end
end
