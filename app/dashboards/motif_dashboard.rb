# frozen_string_literal: true

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
    restriction_for_rdv: Field::Text,
    instruction_for_rdv: Field::Text,
    custom_cancel_warning_message: Field::Text,
    reservable_online: Field::Boolean,
    location_type: EnumField,
    for_secretariat: Field::Boolean,
    default_duration_in_min: Field::Number,
    min_booking_delay: Field::Number,
    visibility_type: Field::String,
    max_booking_delay: Field::Number,
    deleted_at: Field::DateTime,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    name
    organisation
    service
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    organisation
    service
    color
    reservable_online
    location_type
    for_secretariat
    restriction_for_rdv
    instruction_for_rdv
    custom_cancel_warning_message
    default_duration_in_min
    min_booking_delay
    max_booking_delay
    visibility_type
    deleted_at
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    name
    color
    reservable_online
    location_type
    for_secretariat
    default_duration_in_min
    organisation
    service
    min_booking_delay
    max_booking_delay
    visibility_type
    restriction_for_rdv
    instruction_for_rdv
    custom_cancel_warning_message
    deleted_at
  ].freeze

  def display_resource(motif)
    "Motif ##{motif.id} - #{motif.name}"
  end
end
