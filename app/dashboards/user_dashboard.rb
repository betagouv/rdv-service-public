require "administrate/base_dashboard"

class UserDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    organisations: Field::HasMany,
    id: Field::Number,
    first_name: Field::String,
    last_name: Field::String,
    email: Field::String,
    address: Field::String,
    phone_number: Field::String,
    caisse_affiliation: EnumField,
    family_situation: EnumField,
    logement: EnumField,
    affiliation_number: Field::String,
    number_of_children: Field::Number,
    birth_date: Field::DateTime,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :organisations,
    :id,
    :first_name,
    :last_name,
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :organisations,
    :id,
    :first_name,
    :last_name,
    :email,
    :address,
    :phone_number,
    :birth_date,
    :caisse_affiliation,
    :affiliation_number,
    :family_situation,
    :logement,
    :number_of_children,
    :created_at,
    :updated_at,
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :organisations,
    :first_name,
    :last_name,
    :email,
    :address,
    :phone_number,
    :birth_date,
    :caisse_affiliation,
    :affiliation_number,
    :family_situation,
    :logement,
    :number_of_children,
  ].freeze
end
