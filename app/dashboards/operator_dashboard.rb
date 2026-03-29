require "administrate/base_dashboard"

class OperatorDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    siret: Field::String,
    support_link: Field::String,
    territories: Field::HasMany,
    operator_managers: Field::HasMany,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    name
    siret
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    siret
    support_link
    territories
    operator_managers
  ].freeze

  FORM_ATTRIBUTES = %i[
    name
    siret
    support_link
  ].freeze

  def display_resource(operator)
    operator.name
  end
end
