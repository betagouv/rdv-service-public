require "administrate/base_dashboard"

class PlageOuvertureDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    organisation: Field::BelongsTo,
    pro: Field::BelongsTo,
    motifs: Field::HasMany,
    id: Field::Number,
    title: Field::String,
    first_day: Field::DateTime,
    start_time: Field::Time,
    end_time: Field::Time,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    location: PlacesField,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :organisation,
    :pro,
    :motifs,
    :id,
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :organisation,
    :pro,
    :motifs,
    :id,
    :title,
    :first_day,
    :start_time,
    :end_time,
    :location,
    :created_at,
    :updated_at,
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :organisation,
    :pro,
    :motifs,
    :title,
    :first_day,
    :start_time,
    :end_time,
    :location,
  ].freeze

  # Overwrite this method to customize how plage ouvertures are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(plage_ouverture)
  #   "PlageOuverture ##{plage_ouverture.id}"
  # end
end
