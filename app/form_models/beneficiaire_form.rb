# frozen_string_literal: true

class BeneficiaireForm
  include ActiveModel::Model
  include BenignErrors

  ATTRIBUTES = %i[
    first_name
    last_name
    phone_number
    ignore_benign_errors
  ].freeze

  attr_accessor(*ATTRIBUTES)

  validates_presence_of :first_name, :last_name
  validate :warn_no_contact_information
  validate :validate_phone_number

  def warn_no_contact_information
    return if ignore_benign_errors

    if phone_number.blank?
      add_benign_error("Sans numéro de téléphone, aucune notification ne sera envoyée au bénéficiaire")
    end
  end

  def validate_phone_number
    return if phone_number.blank?

    errors.add(:phone_number, :invalid) if PhoneNumberValidation.parsed_number(phone_number).blank?
    errors.add(:phone_number, "ne permet pas de recevoir des SMS") unless PhoneNumberValidation.number_is_mobile?(phone_number)
  end
end
