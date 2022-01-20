# frozen_string_literal: true

class SearchController < ApplicationController
  before_action :store_invitation_token_in_session_if_present

  def search_rdv
    @context = SearchContext.new(current_user, search_params.to_h)
    return if @context.valid?

    flash[:error] = @context.errors.join(", ")
    redirect_to root_path
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
