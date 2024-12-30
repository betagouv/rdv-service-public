require "administrate/base_dashboard"

class RdvDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    users: HasManyWithNamesField,
    agents: HasManyWithNamesField,
    organisation: Field::BelongsTo,
    lieu: Field::BelongsTo,
    motif: Field::BelongsTo,
    created_by: Field::Polymorphic.with_options(classes: [Agent, User]),
    starts_at: Field::DateTime.with_options(format: "le %d/%m/%Y à %H:%M"),
    ends_at: Field::DateTime.with_options(format: "le %d/%m/%Y à %H:%M"),
    status: Field::String,
    cancelled_at: Field::DateTime,
    name: Field::String,
    context: Field::String,
    max_participants_count: Field::Number,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    users
    organisation
    agents
    motif
    starts_at
    status
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    status
    starts_at
    ends_at
    users
    agents
    organisation
    lieu
    motif
    created_by
    cancelled_at
    name
    max_participants_count
    context
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[].freeze

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
