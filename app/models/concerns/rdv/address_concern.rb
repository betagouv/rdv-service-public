# frozen_string_literal: true

module Rdv::AddressConcern
  extend ActiveSupport::Concern

  def address
    result = case motif.location_type.to_sym
             when :public_office
               lieu&.address
             when :home
               user_for_home_rdv&.address
             end

    result || ""
  end

  def address_complete
    result = case motif.location_type.to_sym
             when :public_office
               lieu&.full_name
             when :home
               user_for_home = user_for_home_rdv
               if user_for_home.present?
                 "Adresse de #{user_for_home.full_name} - #{user_for_home.responsible_address}"
               end
             end

    result || ""
  end

  def address_without_personal_information
    case motif.location_type.to_sym
    when :public_office
      # Sometimes lieu_id is nil, because the RDV was taken with
      # a motif of location_type="phone" or location_type="home",
      # and then then someone changed it to location_type="public_office".
      # In this cas we have no way of knowing the actual location, so we'll leave the export blank.
      return "" unless lieu

      lieu_full_name = lieu.full_name
      if lieu.single_use?
        "#{lieu_full_name} (#{Lieu.human_attribute_value(:availability, :single_use)})"
      else
        lieu_full_name
      end
    when :home
      user_for_home = user_for_home_rdv
      home_city = [user_for_home.post_code, user_for_home.city_name].compact.join(" ") if user_for_home.present?
      if home_city.present?
        "#{Motif.human_attribute_value(:location_type, :home)} (#{home_city})"
      else
        Motif.human_attribute_value(:location_type, :home)
      end
    when :phone
      Motif.human_attribute_value(:location_type, :phone)
    end
  end
end
