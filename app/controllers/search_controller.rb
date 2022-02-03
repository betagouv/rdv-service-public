# frozen_string_literal: true

class SearchController < ApplicationController
  def search_rdv
    @context = SearchContext.new(current_user, search_params.to_h)
  end

  private

  def search_params
    params.permit(
      :latitude, :longitude, :address, :city_code, :departement, :street_ban_id,
      :service_id, :lieu_id, :date, :motif_search_terms, :motif_name_with_location_type,
      :invitation_token, organisation_ids: []
    )
  end
end
