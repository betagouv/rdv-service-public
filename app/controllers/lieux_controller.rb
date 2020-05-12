class LieuxController < ApplicationController
  before_action :set_lieu_variables, only: [:index, :show]
  layout 'welcome'

  def index
    @lieux = Lieu.for_service_motif_and_departement(@service_id, @motif_name, @departement)
    return redirect_to lieu_path(@lieux.first, search: @query) if @lieux.size == 1

    # TODO: revoir les contraintes d'unicitees completes (il manque :location_type dans le where) ou bien revoir la notion de motif.
    return redirect_to new_user_session_path, flash: { notice: I18n.t("motifs.follow_up_need_signed_user", motif_name: @motif_name) } if follow_up_rdv_and_offline_user?

    @next_availability_by_lieux = {}
    unless online_bookings_suspended_because_of_corona?(@departement)
      @lieux.each do |lieu|
        @next_availability_by_lieux[lieu.id] = if follow_up?
                                                 Creneau.next_availability_for_motif_and_lieu(@motif_name, lieu, Date.today, agent_ids: current_user.agents)
                                               else
                                                 Creneau.next_availability_for_motif_and_lieu(@motif_name, lieu, Date.today)
                                               end
      end
    end

    @lieux = @lieux.sort_by { |lieu| lieu.distance(@latitude.to_f, @longitude.to_f) }

    @organisations = Organisation.where(departement: @departement)
    return unless @organisations.empty?

    flash.now[:notice] = "La prise de RDV n’est pas encore disponible dans ce département"
    render 'welcome/index'
  end

  def show
    start_date = params[:date]&.to_date || Date.today
    @date_range = start_date..(start_date + 6.days)
    @lieu = Lieu.find(params[:id])
    @query.merge!(lieu_id: @lieu.id)

    # TODO: revoir les contraintes d'unicitees completes (il manque :location_type dans le where) ou bien revoir la notion de motif.
    return redirect_to new_user_session_path, flash: { notice: I18n.t("motifs.follow_up_need_signed_user", motif_name: @motif_name) } if follow_up_rdv_and_offline_user?

    @next_availability = nil

    if online_bookings_suspended_because_of_corona?(@departement)
      @creneaux = []
    elsif follow_up_rdv_without_referent?
      @referent_missing = "Le motif <b>#{@motif_name}</b> nécessite d'avoir un référent. Nous n'avons pas trouvé votre référent.".html_safe
      @creneaux = []
    else
      @creneaux = build_creneaux
      @next_availability = find_next_availability if @creneaux.empty?
    end

    @max_booking_delay = @matching_motifs.maximum('max_booking_delay')

    respond_to do |format|
      format.html
      format.js
    end
  end

  private

  def build_creneaux
    if follow_up?
      CreneauxBuilderService.perform_with(@motif_name, @lieu, @date_range, agent_ids: current_user.agents)
    else
      CreneauxBuilderService.perform_with(@motif_name, @lieu, @date_range)
    end
  end

  def find_next_availability
    if follow_up?
      Creneau.next_availability_for_motif_and_lieu(@motif_name, @lieu, @date_range.end, agent_ids: current_user.agents)
    else
      Creneau.next_availability_for_motif_and_lieu(@motif_name, @lieu, @date_range.end)
    end
  end

  def follow_up_rdv_without_referent?
    @matching_motifs.first&.follow_up? && current_user && current_user.agents.empty?
  end

  def follow_up?
    current_user && @matching_motifs.first&.follow_up?
  end

  def follow_up_rdv_and_offline_user?
    !current_user && @matching_motifs.first&.follow_up?
  end

  def search_params
    params.require(:search).permit(:departement, :where, :service, :motif_name, :longitude, :latitude)
  end

  def set_lieu_variables
    @query = search_params.to_hash
    @departement = search_params[:departement]
    @motif_name = search_params[:motif_name]
    @where = search_params[:where]
    @service_id = search_params[:service]
    @service = Service.find(@service_id)
    @motif_names = Motif.names_for_service_and_departement(@service, @departement)
    @latitude = search_params[:latitude]
    @longitude = search_params[:longitude]
    @matching_motifs = Motif.active.online.joins(:organisation).where(organisations: { departement: @departement }, name: @motif_name)
  end
end
