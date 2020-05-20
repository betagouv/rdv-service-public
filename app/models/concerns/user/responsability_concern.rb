module User::ResponsabilityConcern
  extend ActiveSupport::Concern

  included do
    before_save :set_organisation_ids_from_responsible, if: :responsible_id_changed?
    accepts_nested_attributes_for :responsible
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

  protected

  def set_organisation_ids_from_responsible
    self.organisation_ids = responsible.organisation_ids if responsible
  end

  # def reject_responsible_if(attributes)
  #   puts "attributes.keys is #{attributes.keys}"
  # end
end
