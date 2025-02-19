class BeneficiaireForm
  include ActiveModel::Model
  include BenignErrors

  ATTRIBUTES = %i[
    first_name
    last_name
    phone_number
    ignore_benign_errors
    ants_pre_demande_number
    ants_meeting_point_id
  ].freeze

  attr_accessor(*ATTRIBUTES, :motif_id)

  validates_presence_of :first_name, :last_name
  validate :warn_no_contact_information
  validate :validate_phone_number
  validates :ants_pre_demande_number, presence: true, ants_pre_demande_number_format: true, if: :requires_ants_predemande_number?
  validates_with AntsPreDemandeNumberStatusValidation, if: :requires_ants_predemande_number?

  def warn_no_contact_information
    return if ignore_benign_errors

    if phone_number.blank?
      add_benign_error("Sans numéro de téléphone, aucune notification ne sera envoyée au bénéficiaire")
    end
  end

  def validate_phone_number
    return if phone_number.blank?

    errors.add(:phone_number, :invalid) if PhoneNumberValidation.parsed_number(phone_number).blank?
    errors.add(:phone_number, "doit être un numéro de mobile") unless PhoneNumberValidation.number_is_mobile?(phone_number)
  end

  def requires_ants_predemande_number?
    Motif.find_by(id: motif_id)&.requires_ants_predemande_number?
  end
end
