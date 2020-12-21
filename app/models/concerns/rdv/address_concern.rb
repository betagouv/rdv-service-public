module Rdv::AddressConcern
  extend ActiveSupport::Concern

  def address
    return location if location_without_lieu?
    return user_for_home_rdv.address.to_s if home? && user_for_home_rdv.present?
    return lieu.address if public_office? && lieu.present?

    ""
  end

  def address_complete
    return location if location_without_lieu?
    return "Adresse de #{user_for_home_rdv.full_name} - #{user_for_home_rdv.responsible_address}" if home? && user_for_home_rdv.present?
    return lieu.full_name if public_office? && lieu.present?

    ""
  end

  def address_complete_without_personnal_details
    return "Par téléphone" if phone?
    return "À domicile" if home?

    address_complete
  end

  private

  def location_without_lieu?
    location.present? && lieu_id.nil?
  end
end
