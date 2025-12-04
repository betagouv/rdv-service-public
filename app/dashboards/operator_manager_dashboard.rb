require "administrate/base_dashboard"

class OperatorManagerDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    first_name: Field::String,
    last_name: Field::String,
    email: Field::String,
    operator: Field::BelongsTo,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    first_name
    last_name
    email
    operator
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    first_name
    last_name
    email
    operator
  ].freeze

  FORM_ATTRIBUTES = %i[
    first_name
    last_name
    email
    operator
  ].freeze
end
