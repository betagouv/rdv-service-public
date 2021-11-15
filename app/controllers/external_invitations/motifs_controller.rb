# frozen_string_literal: true

class ExternalInvitations::MotifsController < ApplicationController
  before_action :store_invitation_token_in_session_if_present
  before_action :set_variables_from_invitation

  PERMITTED_PARAMS = %i[
    departement where motif_name_with_location_type latitude longitude city_code street_ban_id
    invitation_token
  ].freeze

  def index
    # if no motif can be found through the geo search we retrieve all orga motifs for the service
    @available_motifs = \
      @geo_search.available_motifs.where(organisation: @organisation).presence ||
      Motif.available_with_plages_ouvertures_for_organisation(@organisation)

    @unique_motifs_by_name_and_location_type = @available_motifs
      .where(service: @service)
      .uniq { [_1.name, _1.location_type] }
  end

  private

  def motif_params
    params.permit(*PERMITTED_PARAMS)
  end

  def set_variables_from_invitation
    @query = motif_params.to_h
    @latitude = motif_params[:latitude]
    @longitude = motif_params[:longitude]
    @where = motif_params[:where]
    @city_code = motif_params[:city_code]
    @departement = motif_params[:departement]
    @street_ban_id = motif_params[:street_ban_id]
    @organisation = Organisation.find(params[:organisation_id])
    @service = Service.find(params[:service_id])
    @geo_search = Users::GeoSearch.new(departement: @departement, city_code: @city_code, street_ban_id: @street_ban_id)
  end
end
