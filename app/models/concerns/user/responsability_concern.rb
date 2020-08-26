module User::ResponsabilityConcern
  extend ActiveSupport::Concern

  included do
    before_save :set_organisation_ids_from_responsible, if: :responsible_id_changed?
    accepts_nested_attributes_for :responsible
    validate :cannot_be_responsible_of_self
  end

  def responsability_type
    responsible.present? && !responsible.new_and_blank? ? :relative : :responsible
  end

  def relative?
    responsability_type == :relative
  end

  def responsible?
    responsability_type == :responsible
  end

  def address
    # TODO: this makes everything ambiguous and thus dangerous,
    # rename to explicit responsible_address
    super.presence || responsible&.address
  end

  def responsible_phone_number
    relative? ? responsible.phone_number : phone_number
  end

  def responsible_email
    relative? ? responsible.email : email
  end

  def responsible_address
    relative? ? responsible.address : address
  end

  protected

  def set_organisation_ids_from_responsible
    return unless organisations_mismatch?

    missing_organisation_ids.each do |missing_organisation_id|
      user_profiles.build(organisation_id: missing_organisation_id)
    end
  end

  def missing_organisation_ids
    responsible.user_profiles.map(&:organisation_id) - user_profiles.map(&:organisation_id)
  end

  def organisations_mismatch?
    responsible &&
      responsible.user_profiles.map(&:organisation_id).sort != user_profiles.map(&:organisation_id).sort
  end

  def cannot_be_responsible_of_self
    errors.add(:responsible_id, "ne peut pas être l'usager lui même") if responsible_id.present? && responsible_id == id
  end
end
