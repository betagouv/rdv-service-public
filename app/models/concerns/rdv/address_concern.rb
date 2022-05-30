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

  def address_for_export
    result = case motif.location_type.to_sym
             when :public_office
               lieu&.full_name
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

    result || ""
  end
end
