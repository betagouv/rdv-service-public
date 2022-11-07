# frozen_string_literal: true

class BeneficiaireForm
  include ActiveModel::Model
  include BenignErrors

  ATTRIBUTES = %i[
    first_name
    last_name
    email
    phone_number
  ].freeze

  attr_accessor(*ATTRIBUTES)

  validates_presence_of :first_name, :last_name
  validate :warn_no_contact_information

  def warn_no_contact_information
    return if ignore_benign_errors

    if email.blank? && phone_number.blank?
      add_benign_error("Sans email ni numéro de téléphone, aucune notification ne sera envoyée au bénéficiaire")
    end
  end
end
