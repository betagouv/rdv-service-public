class Users::RdvsController < UserAuthController
  before_action :verify_user_name_initials, :set_rdv, :set_can_see_rdv_motif, only: %i[show creneaux edit cancel update]
  before_action :set_can_see_rdv_motif, only: %i[show edit index]
  before_action :set_geo_search, only: [:create]
  before_action :set_lieu, only: %i[edit update]
  before_action :build_creneau, :redirect_if_creneau_not_available, only: %i[edit update]
  after_action :allow_iframe

  layout "application_narrow", only: %i[show]

  include TokenInvitable

  def index
    authorize Rdv
    @rdvs = policy_scope(Rdv).includes(:motif, :participations, :users).user_with_relatives(current_user.id).for_domain(current_domain)
    @rdvs = params[:past].present? ? @rdvs.past : @rdvs.future
    @rdvs = @rdvs.order(starts_at: :desc).page(page_number)
  end

  def create
    lieu = new_rdv_extra_params[:lieu_id].present? ? Lieu.find(new_rdv_extra_params[:lieu_id]) : nil
    motif = Motif.find(rdv_params[:motif_id])
    # Nous modifions en mémoire la durée par défaut du motif
    # Cela permet d'effectuer une recherche de créneaux, avec une durée différente
    motif.default_duration_in_min = params[:duration] if params[:duration]
    ActiveRecord::Base.transaction do
      @creneau = CreneauxSearch::ForUser.creneau_for(
        user: current_user,
        starts_at: Time.zone.parse(rdv_params[:starts_at]),
        motif: motif,
        lieu: lieu,
        geo_search: @geo_search
      )
      if @creneau.present?
        @rdv = build_rdv_from_creneau(@creneau)
        authorize(@rdv)
        @save_succeeded = @rdv.save
      end
    end
    skip_authorization if @creneau.nil?
    if @save_succeeded
      notifier = Notifiers::RdvCreated.new(@rdv, current_user)
      notifier.perform
      set_user_name_initials_verified
      redirect_to users_rdv_path(@rdv, invitation_token: notifier.participations_tokens_by_user_id[current_user.id]), notice: t(".rdv_confirmed")
    else
      # TODO: cette liste de paramètres devrait ressembler a SearchController#search_params, mais sans certains paramètres de choix du wizard de créneaux
      query = {
        address: new_rdv_extra_params[:address] || new_rdv_extra_params[:where],
        city_code: new_rdv_extra_params[:city_code], street_ban_id: new_rdv_extra_params[:street_ban_id],
        service: motif.service.id, motif_name_with_location_type: motif.name_with_location_type,
        departement: new_rdv_extra_params[:departement], organisation_ids:  new_rdv_extra_params[:organisation_ids],
      }
      redirect_to prendre_rdv_path(query), flash: { error: t(".creneau_unavailable") }
    end
  end

  def edit; end

  def show; end

  def update
    old_agent_ids = @rdv.agent_ids.to_a
    if @rdv.update(starts_at: @creneau.starts_at, ends_at: @creneau.starts_at + @rdv.duration_in_min.minutes, agent_ids: [@creneau.agent.id])
      notifier = Notifiers::RdvUpdated.new(@rdv, current_user, old_agent_ids: old_agent_ids)

      notifier.perform
      flash[:success] = "Votre RDV a bien été modifié"
      redirect_to users_rdv_path(@rdv, invitation_token: notifier.participations_tokens_by_user_id[current_user.id])
    else
      flash[:error] = "Le RDV n'a pas pu être modifié"
      redirect_to creneaux_users_rdv_path(@rdv)
    end
  end

  def cancel
    if @rdv.update_and_notify(current_user, status: "excused")
      flash[:notice] = "Le RDV a bien été annulé."
    else
      flash[:error] = "Impossible d'annuler le RDV."
    end
    redirect_to users_rdv_path(@rdv, invitation_token: @rdv.participation_token(current_user.id))
  end

  def creneaux
    @all_creneaux = @rdv.creneaux_available(Time.zone.today..@rdv.reschedule_max_date)
    return if @all_creneaux.empty?

    start_date = params[:date]&.to_date || @all_creneaux.min.starts_at.to_date
    end_date = [start_date + 6.days, @all_creneaux.max.starts_at.to_date].min
    @date_range = start_date..end_date
    @creneaux = @rdv.creneaux_available(@date_range)
  end

  private

  def build_creneau
    @starts_at = Time.zone.parse(params[:starts_at])
    @creneau = CreneauxSearch::ForUser.creneau_for(
      user: current_user,
      starts_at: @starts_at,
      motif: @rdv.motif,
      lieu: @lieu
    )
  end

  def set_lieu
    @lieu = @rdv.lieu
  end

  def set_rdv
    @rdv = policy_scope(Rdv).find(params[:id])
    authorize(@rdv)
  end

  def set_can_see_rdv_motif
    @can_see_rdv_motif = !current_user.only_invited?
  end

  def redirect_if_creneau_not_available
    return if @creneau.present?

    flash[:alert] = "Ce créneau n'est plus disponible"
    redirect_to creneaux_users_rdv_path(@rdv)
  end

  def set_geo_search
    @geo_search = Users::GeoSearch.new(
      departement: params[:departement],
      city_code: params[:city_code],
      street_ban_id: params[:street_ban_id].presence
    )
  end

  def build_rdv_from_creneau(creneau)
    rdv = creneau.build_rdv
    rdv.assign_attributes(
      users: users_for_rdv,
      created_by: current_user
    )
    rdv
  end

  def users_for_rdv
    if rdv_params[:user_ids]
      current_user.available_users_for_rdv.find(rdv_params[:user_ids])
    else
      [current_user]
    end
  end

  def new_rdv_extra_params
    params.permit(
      :lieu_id, :motif_name_with_location_type, :departement, :where, :address, :city_code, :street_ban_id,
      :invitation_token, { organisation_ids: [] }
    )
  end

  def rdv_params
    params.permit(:starts_at, :motif_id, :context, user_ids: [])
  end
end
