require "administrate/base_dashboard"

class OrganisationDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    agents: Field::HasMany,
    agent_roles: Field::HasMany,
    motifs: Field::HasMany,
    lieux: Field::HasMany,
    horaires: Field::String,
    phone_number: Field::String,
    email: Field::String,
    territory: Field::BelongsTo,
    verticale: EnumField,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    name
    verticale
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    territory
    horaires
    phone_number
    agent_roles
    email
    motifs
    lieux
    verticale
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    name
    horaires
    phone_number
    email
    verticale
    territory
  ].freeze

  # Overwrite this method to customize how super admins are displayed
  # across all pages of the super_admin dashboard.
  #
  def display_resource(organisation)
    "Organisation ##{organisation.id} - #{organisation.name}"
  end
end
