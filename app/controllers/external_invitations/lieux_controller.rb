# frozen_string_literal: true

class ExternalInvitations::LieuxController < ApplicationController
  before_action :store_invitation_token_in_session_if_present
  before_action :set_variables_from_invitation
  before_action :redirect_if_no_matching_motifs

  PERMITTED_PARAMS = %i[
    departement where motif_name_with_location_type latitude longitude city_code street_ban_id
    invitation_token
  ].freeze

  def index
    @lieux = Lieu
      .with_open_slots_for_motifs(@matching_motifs)
      .includes(:organisation)
      .sort_by { |lieu| lieu.distance(@latitude.to_f, @longitude.to_f) }
    @next_availability_by_lieux = @lieux.map do |lieu|
      [
        lieu.id,
        creneaux_search_for(lieu, (1.week.ago.to_date..Time.zone.today)).next_availability
      ]
    end.to_h
  end

  def show
    start_date = params[:date]&.to_date || Time.zone.today
    @date_range = start_date..(start_date + 6.days)
    @lieu = Lieu.find(params[:id])
    @query.merge!(lieu_id: @lieu.id)
    @next_availability = nil

    creneaux_search = creneaux_search_for(@lieu, @date_range)
    @creneaux = creneaux_search.creneaux
    @next_availability = creneaux_search.next_availability if @creneaux.empty?

    @max_booking_delay = @matching_motifs.maximum("max_booking_delay")

    respond_to do |format|
      format.html
      format.js
    end
  end

  private

  def redirect_if_no_matching_motifs
    return if @matching_motif.present?

    redirect_to external_invitations_organisation_service_motifs_path(
      organisation: @organisation, service: @service, **@query
    )
  end

  def creneaux_search_for(lieu, date_range)
    Users::CreneauxSearch.new(
      user: current_user,
      motif: @matching_motif, # there can be only one
      lieu: lieu,
      date_range: date_range,
      geo_search: @geo_search
    )
  end

  def lieu_params
    params.permit(*PERMITTED_PARAMS)
  end

  def set_variables_from_invitation
    @query = lieu_params.to_h
    @latitude = lieu_params[:latitude]
    @longitude = lieu_params[:longitude]
    @where = lieu_params[:where]
    @city_code = lieu_params[:city_code]
    @departement = lieu_params[:departement]
    @street_ban_id = lieu_params[:street_ban_id]
    @organisation = Organisation.find(params[:organisation_id])
    @service = Service.find(params[:service_id])
    @geo_search = Users::GeoSearch.new(departement: @departement, city_code: @city_code, street_ban_id: @street_ban_id)
    @matching_motifs = Motif.available_with_plages_ouvertures.where(id: params[:motif_id])
    @matching_motif = @matching_motifs.first
  end
end
