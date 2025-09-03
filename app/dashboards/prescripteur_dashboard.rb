require "administrate/base_dashboard"

class PrescripteurDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    first_name: Field::String,
    last_name: Field::String,
    phone_number: Field::String,
    phone_number_formatted: Field::String,
    email: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    rdv: Field::HasOne,
    user: Field::HasOne,
  }.freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    first_name
    last_name
    phone_number
    phone_number_formatted
    email
    created_at
    updated_at
    rdv
    user
  ].freeze
end
