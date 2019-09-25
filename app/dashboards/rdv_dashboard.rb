require "administrate/base_dashboard"

class RdvDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    status: EnumField,
    location: PlacesField,
    organisation: Field::BelongsTo,
    pros: Field::HasMany,
    users: Field::HasMany,
    motif: Field::BelongsTo,
    id: Field::Number,
    name: Field::String,
    duration_in_min: Field::Number,
    start_at: Field::DateTime,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    cancelled_at: Field::DateTime,
    max_users_limit: Field::Number,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :id,
    :organisation,
    :motif,
    :name,
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :status,
    :organisation,
    :motif,
    :users,
    :pros,
    :id,
    :name,
    :duration_in_min,
    :start_at,
    :created_at,
    :updated_at,
    :cancelled_at,
    :max_users_limit,
    :location,
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :status,
    :organisation,
    :motif,
    :users,
    :pros,
    :name,
    :duration_in_min,
    :start_at,
    :cancelled_at,
    :max_users_limit,
    :location,
  ].freeze

  # Overwrite this method to customize how rdvs are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(rdv)
  #   "Rdv ##{rdv.id}"
  # end
end
