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
    lieu: Field::BelongsTo,
    pro: Field::BelongsTo,
    motifs: Field::HasMany,
    id: Field::Number,
    title: Field::String,
    first_day: Field::DateTime,
    start_time: Field::Time,
    end_time: Field::Time,
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
    :organisation,
    :pro,
    :lieu,
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :title,
    :organisation,
    :pro,
    :motifs,
    :lieu,
    :first_day,
    :start_time,
    :end_time,
    :created_at,
    :updated_at,
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :title,
    :organisation,
    :pro,
    :lieu,
    :motifs,
    :lieu,
    :first_day,
    :start_time,
    :end_time,
  ].freeze
end
