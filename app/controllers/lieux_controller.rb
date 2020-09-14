class LieuxController < ApplicationController
  before_action :set_lieu_variables, only: [:index, :show]

  def index
    @lieux = Lieu.with_open_slots_for_motifs(@matching_motifs)
    return redirect_to new_user_session_path, flash: { alert: I18n.t("motifs.follow_up_need_signed_user", motif_name: @motif_name) } if follow_up_rdv_and_offline_user?

    @next_availability_by_lieux = {}
    @lieux.each do |lieu|
      # TODO: au lieux de current_user.agents, il faudrait sans doute filtrer sur les agents du service lie au motif, de la meme organisation
      @next_availability_by_lieux[lieu.id] = FindAvailabilityService.perform_with(@motif_name, lieu, Date.today, **options_to_build_creneaux)
    end

    @lieux = @lieux.sort_by { |lieu| lieu.distance(@latitude.to_f, @longitude.to_f) }

    return unless @organisations.empty?

    flash.now[:notice] = "La prise de RDV n’est pas encore disponible dans ce département"
    render "welcome/index"
  end

  def show
    start_date = params[:date]&.to_date || Date.today
    @date_range = start_date..(start_date + 6.days)
    @lieu = Lieu.find(params[:id])
    @query.merge!(lieu_id: @lieu.id)

    # TODO: revoir les contraintes d'unicitees completes (il manque :location_type dans le where) ou bien revoir la notion de motif.
    return redirect_to new_user_session_path, flash: { notice: I18n.t("motifs.follow_up_need_signed_user", motif_name: @motif_name) } if follow_up_rdv_and_offline_user?

    @next_availability = nil

    if follow_up_rdv_without_referent?
      @referent_missing = "Vous ne semblez pas bénéficier d’un accompagnement ou d’un suivi, merci de choisir un autre motif ou de contacter votre département au #{@lieu.organisation.phone_number}".html_safe
      @creneaux = []
    else
      @creneaux = CreneauxBuilderService.perform_with(@motif_name, @lieu, @date_range, **options_to_build_creneaux)
      @next_availability = FindAvailabilityService.perform_with(@motif_name, @lieu, @date_range.end, **options_to_build_creneaux) if @creneaux.empty?
    end

    @max_booking_delay = @matching_motifs.maximum("max_booking_delay")

    respond_to do |format|
      format.html
      format.js
    end
  end

  private

  def options_to_build_creneaux
    @options_to_build_creneaux ||= follow_up_rdv_and_online_user? ? { agent_ids: current_user.agent_ids, agent_name: true } : {}
  end

  def follow_up_rdv_without_referent?
    # TODO: au lieux de current_user.agents, il faudrait sans doute filtrer sur les agents du service lie au motif, de la meme organisation
    @matching_motifs.first&.follow_up? && current_user && current_user.agents.empty?
  end

  def follow_up_rdv_and_online_user?
    current_user && @matching_motifs.first&.follow_up?
  end

  def follow_up_rdv_and_offline_user?
    !current_user && @matching_motifs.first&.follow_up?
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
    @zone = Zone.in_address_sector(@city_code)
    @organisations = Organisation.in_zone_or_departement(@zone, @departement)
    searchable_motifs = Motif.searchable(@organisations, service: @service)
    redirect_to root_path, flash: { error: "Une erreur s'est produite, veuillez recommencer votre recherche" } if searchable_motifs.empty?
    @motif_names = searchable_motifs.pluck(:name).uniq
    @matching_motifs = searchable_motifs.where(name: @motif_name)
    @latitude = search_params[:latitude]
    @longitude = search_params[:longitude]
  end
end
