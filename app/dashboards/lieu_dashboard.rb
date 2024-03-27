require "administrate/base_dashboard"

class LieuDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    versions: Field::HasMany,
    organisation: Field::BelongsTo.with_options(order: { id: :asc }),
    plage_ouvertures: Field::HasMany,
    rdvs: Field::HasMany,
    motifs: Field::HasMany,
    agents: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    latitude: Field::Number.with_options(decimals: 6),
    longitude: Field::Number.with_options(decimals: 6),
    phone_number: Field::String,
    phone_number_formatted: Field::String,
    availability: Field::Select.with_options(searchable: false, collection: ->(field) { field.resource.class.send(field.attribute.to_s.pluralize).keys }),
    address: PlacesField.with_options(searchable: true),
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    name
    address
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    address
    organisation
    created_at
    updated_at
    latitude
    longitude
    phone_number_formatted
    availability
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    name
    latitude
    longitude
    address
    organisation
  ].freeze

  # COLLECTION_FILTERS
  # a hash that defines filters that can be used while searching via the search
  # field of the dashboard.
  #
  # For example to add an option to search for open resources by typing "open:"
  # in the search field:
  #
  #   COLLECTION_FILTERS = {
  #     open: ->(resources) { resources.where(open: true) }
  #   }.freeze
  COLLECTION_FILTERS = {}.freeze

  # Overwrite this method to customize how lieux are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(lieu)
  #   "Lieu ##{lieu.id}"
  # end
end
