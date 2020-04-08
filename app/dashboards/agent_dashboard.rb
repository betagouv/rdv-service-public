require "administrate/base_dashboard"

class AgentDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    email: Field::String,
    role: EnumField,
    first_name: Field::String,
    last_name: Field::String,
    organisations: Field::HasMany,
    plage_ouvertures: Field::HasMany,
    absences: Field::HasMany,
    service: Field::BelongsTo,
    rdvs: Field::HasMany,
    invitation_sent_at: Field::DateTime,
    deleted_at: Field::DateTime,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :id,
    :email,
    :first_name,
    :last_name,
    :role,
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :id,
    :email,
    :first_name,
    :last_name,
    :role,
    :organisations,
    :service,
    :plage_ouvertures,
    :absences,
    :rdvs,
    :invitation_sent_at,
    :created_at,
    :deleted_at,
    :updated_at,
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :email,
    :first_name,
    :last_name,
    :organisations,
    :role,
    :service,
    :deleted_at,
  ].freeze

  def display_resource(agent)
    "Agent ##{agent.id} - #{agent.full_name}"
  end
end
