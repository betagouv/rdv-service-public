require "administrate/base_dashboard"

class MotifDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    organisation: Field::BelongsTo,
    specialite: Field::BelongsTo,
    color: Field::String,
    online: Field::Boolean,
    accept_multiple_pros: Field::Boolean,
    accept_multiple_users: Field::Boolean,
    at_home: Field::Boolean,
    default_duration_in_min: Field::Number,
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
    :name,
    :organisation,
    :specialite,
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :id,
    :name,
    :organisation,
    :specialite,
    :color,
    :online,
    :accept_multiple_pros,
    :accept_multiple_users,
    :at_home,
    :default_duration_in_min,
    :created_at,
    :updated_at,
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :name,
    :color,
    :online,
    :accept_multiple_pros,
    :accept_multiple_users,
    :at_home,
    :default_duration_in_min,
    :organisation,
    :specialite,
  ].freeze

  # Overwrite this method to customize how super admins are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(motif)
    "#{motif.name} (#{motif.organisation})"
  end
end
