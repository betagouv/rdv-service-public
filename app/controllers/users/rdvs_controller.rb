class Users::RdvsController < UserAuthController
  before_action :verify_user_name_initials, :set_rdv, :set_can_see_rdv_motif, only: %i[show creneaux ics edit cancel update]
  before_action :set_can_see_rdv_motif, only: %i[show edit index]
  before_action :set_lieu, only: %i[edit update]
  before_action :build_creneau, :redirect_if_creneau_not_available, only: %i[edit update]

  layout "application_narrow", only: %i[show]
  layout "application_base", only: %i[index]

  include TokenInvitable

  prepend_before_action :store_invitation_in_session_and_redirect, only: %i[show creneaux]

  def index
    authorize(Rdv, policy_class: User::RdvPolicy)
    @all_rdvs = policy_scope(Rdv, policy_scope_class: User::RdvPolicy::Scope).for_domain(current_domain)

    @rdv_page = @all_rdvs.page(page_number)
      .includes(:motif, :participations, :users)
      .user_with_relatives(current_user.id)
    @rdv_page = if params[:past]
                  @rdv_page.past.order(starts_at: :desc)
                else
                  @rdv_page.future.order(starts_at: :asc)
                end
  end

  def create; end

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

  def ics
    payload = @rdv.payload(recipient: current_user)
    cal = IcalFormatters::Ics.from_payload(payload)
    send_data cal.to_ical,
              filename: payload[:attachement_filename],
              type: "text/calendar",
              disposition: "attachment"
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
    @rdv = Rdv.find(params[:id])
    authorize(@rdv, policy_class: User::RdvPolicy)
  end

  def set_can_see_rdv_motif
    @can_see_rdv_motif = !current_user.signed_in_with_invitation_token?
  end

  def redirect_if_creneau_not_available
    return if @creneau.present?

    flash[:alert] = "Ce créneau n'est plus disponible"
    redirect_to creneaux_users_rdv_path(@rdv)
  end
end
