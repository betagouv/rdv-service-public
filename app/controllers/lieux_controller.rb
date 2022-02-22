# frozen_string_literal: true

class LieuxController < ApplicationController
  before_action \
    :redirect_if_search_params_absent,
    :set_lieu_variables,
    :redirect_if_user_offline_and_motif_follow_up,
    :redirect_if_no_matching_motifs
  after_action :allow_iframe

  def index
    @lieux = Lieu
      .with_open_slots_for_motifs(@matching_motifs)
      .includes(:organisation)
      .sort_by { |lieu| lieu.distance(@latitude.to_f, @longitude.to_f) }
    @next_availability_by_lieux = @lieux.to_h do |lieu|
      [
        lieu.id,
        creneaux_search_for(lieu, (1.week.ago.to_date..Time.zone.today)).next_availability
      ]
    end
  end

  def show
    start_date = params[:date]&.to_date || Time.zone.today
    @date_range = start_date..(start_date + 6.days)
    @lieu = Lieu.find(params[:id])
    @query.merge!(lieu_id: @lieu.id)
    @next_availability = nil

    if follow_up_motif? && current_user && current_user.agents.empty?
      @referent_missing = t(".referent_missing", phone_number: @lieu.organisation.phone_number)
      @creneaux = []
    else
      creneaux_search = creneaux_search_for(@lieu, @date_range)
      @creneaux = creneaux_search.creneaux
      @next_availability = creneaux_search.next_availability if @creneaux.empty?
    end

    @max_booking_delay = @matching_motifs.maximum("max_booking_delay")

    respond_to do |format|
      format.html
      format.js
    end
  end

  private

  def redirect_if_search_params_absent
    return if params[:search].present?

    redirect_to root_path, flash: { error: "Les paramètres de recherche n'ont pas été transmis correctement" }
  end

  def redirect_if_user_offline_and_motif_follow_up
    return if !follow_up_motif? || current_user.present?

    redirect_to new_user_session_path, flash: { notice: I18n.t("motifs.follow_up_need_signed_user", motif_name: @matching_motifs.first.name) }
  end

  def redirect_if_no_matching_motifs
    return if @matching_motifs.any?

    redirect_to root_path, flash: { error: "Une erreur s'est produite, veuillez recommencer votre recherche" }
  end

  def follow_up_motif?
    @matching_motifs.first&.follow_up?
  end

  def creneaux_search_for(lieu, date_range)
    Users::CreneauxSearch.new(
      user: current_user,
      motif: @matching_motifs.where(organisation: lieu.organisation).first, # there can be only one
      lieu: lieu,
      date_range: date_range,
      geo_search: @geo_search
    )
  end

  def search_params
    params.require(:search).permit(:departement, :where, :service, :motif_name_with_location_type, :longitude, :latitude, :city_code, :street_ban_id)
  end

  def set_lieu_variables
    @query = search_params.to_hash
    @departement = search_params[:departement]
    @motif_name_with_location_type = search_params[:motif_name_with_location_type]
    @where = search_params[:where]
    @service_id = search_params[:service]
    @city_code = search_params[:city_code]
    @street_ban_id = search_params[:street_ban_id]
    @service = Service.find(@service_id)
    @geo_search = Users::GeoSearch.new(
      departement: @departement,
      city_code: @city_code,
      street_ban_id: @street_ban_id.presence
    )
    searchable_motifs = @geo_search.available_motifs.where(service: @service)
    @unique_motifs_by_name_and_location_type = searchable_motifs.uniq { [_1.name, _1.location_type] }
    @matching_motifs = searchable_motifs.search_by_name_with_location_type(@motif_name_with_location_type)
    @latitude = search_params[:latitude]
    @longitude = search_params[:longitude]
  end
end
