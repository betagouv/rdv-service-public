require "administrate/base_dashboard"

class WebhookEndpointDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    target_url: Field::String,
    organisation: Field::BelongsTo,
    secret: Field::String,
    id: Field::Number
  }.freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    organisation
    target_url
  ].freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    organisation
    target_url
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    organisation
    target_url
    secret
  ].freeze

  # Overwrite this method to customize how rdvs are displayed
  # across all pages of the super_admin dashboard.
  #
  # def display_resource(rdv)
  #   "Rdv ##{rdv.id}"
  # end
end
