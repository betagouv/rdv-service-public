class LieuxController < ApplicationController
  before_action \
    :set_lieu_variables,
    :redirect_if_user_offline_and_motif_follow_up,
    :redirect_if_no_matching_motifs

  def index
    @lieux = Lieu
      .with_open_slots_for_motifs(@matching_motifs)
      .sort_by { |lieu| lieu.distance(@latitude.to_f, @longitude.to_f) }
    @next_availability_by_lieux = @lieux.map do |lieu|
      [
        lieu.id,
        creneaux_search_for(lieu, (1.week.ago.to_date..Date.today)).next_availability
      ]
    end.to_h
  end

  def show
    start_date = params[:date]&.to_date || Date.today
    @date_range = start_date..(start_date + 6.days)
    @lieu = Lieu.find(params[:id])
    @query.merge!(lieu_id: @lieu.id)
    @next_availability = nil

    if follow_up_motif? && current_user && current_user.agents.empty?
      @referent_missing = "Vous ne semblez pas bénéficier d’un accompagnement ou d’un suivi, merci de choisir un autre motif ou de contacter votre département au #{@lieu.organisation.phone_number}".html_safe
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

  def redirect_if_user_offline_and_motif_follow_up
    return if !follow_up_motif? || current_user.present?

    redirect_to new_user_session_path, flash: { notice: I18n.t("motifs.follow_up_need_signed_user", motif_name: @motif_name) }
  end

  def redirect_if_no_matching_motifs
    return if @matching_motifs.any?

    redirect_to root_path, flash: { error: "Une erreur s'est produite, veuillez recommencer votre recherche" }
  end

  def follow_up_motif?
    @matching_motifs.first&.follow_up?
  end

  def creneaux_search_for(lieu, date_range)
    Users::CreneauxSearch.new(user: current_user, motifs: @matching_motifs, lieu: lieu, date_range: date_range)
  end

  def search_params
    params.require(:search).permit(:departement, :where, :service, :motif_name, :longitude, :latitude, :city_code)
  end

  def set_lieu_variables
    @query = search_params.to_hash
    @departement = search_params[:departement]
    @motif_name = search_params[:motif_name]
    @where = search_params[:where]
    @service_id = search_params[:service]
    @city_code = search_params[:city_code]
    @service = Service.find(@service_id)
    @geo_search = Users::GeoSearch.new(departement: @departement, city_code: @city_code)
    searchable_motifs = @geo_search.available_motifs.where(service: @service)
    @motif_names = searchable_motifs.pluck(:name).uniq
    @matching_motifs = searchable_motifs.where(name: @motif_name)
    @latitude = search_params[:latitude]
    @longitude = search_params[:longitude]
  end
end
