# frozen_string_literal: true

module Rdv::AddressConcern
  extend ActiveSupport::Concern

  def address
    return user_for_home_rdv.address.to_s if home? && user_for_home_rdv.present?
    return lieu.address if public_office? && lieu.present?

    ""
  end

  def address_complete
    return "Adresse de #{user_for_home_rdv.full_name} - #{user_for_home_rdv.responsible_address}" if home? && user_for_home_rdv.present?
    return lieu.full_name if public_office? && lieu.present?

    ""
  end

  def address_complete_without_personal_details
    return address_complete if public_office?

    result = motif.human_attribute_value(:location_type)
    if home? && user_for_home_rdv.present?
      home_city = [user_for_home_rdv.post_code, user_for_home_rdv.city_name].compact.join(" ")
      result.concat(" (#{home_city})") if home_city.present?
    end

    result
  end
end
