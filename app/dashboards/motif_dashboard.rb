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
    service: Field::BelongsTo,
    color: Field::String,
    online: Field::Boolean,
    by_phone: Field::Boolean,
    default_duration_in_min: Field::Number,
    min_booking_delay: Field::Number,
    send_notification: Field::Boolean,
    max_booking_delay: Field::Number,
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
    :name,
    :organisation,
    :service,
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :id,
    :name,
    :organisation,
    :service,
    :color,
    :online,
    :by_phone,
    :default_duration_in_min,
    :min_booking_delay,
    :max_booking_delay,
    :send_notification,
    :deleted_at,
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
    :by_phone,
    :default_duration_in_min,
    :organisation,
    :service,
    :min_booking_delay,
    :max_booking_delay,
    :send_notification,
    :deleted_at,
  ].freeze

  # Overwrite this method to customize how super admins are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(motif)
    "#{motif.name} (#{motif.organisation&.name})"
  end
end
