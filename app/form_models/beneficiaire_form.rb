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

  def warn_no_contact_information
    return if ignore_benign_errors

    if phone_number.blank?
      add_benign_error("Sans numéro de téléphone, aucune notification ne sera envoyée au bénéficiaire")
    end
  end
end
