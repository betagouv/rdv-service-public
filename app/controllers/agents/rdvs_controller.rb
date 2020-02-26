class Agents::RdvsController < AgentAuthController
  respond_to :html, :json

  before_action :set_rdv, only: [:show, :edit, :update, :destroy, :status]

  def index
    @rdvs = policy_scope(Rdv)
    if filter_params[:agent_id].present?
      @agent = policy_scope(Agent).find(filter_params[:agent_id])
      @rdvs = @rdvs.joins(:agents).where(agents: { id: @agent })
    end
    if filter_params[:user_id].present?
      @user = policy_scope(User).find(filter_params[:user_id])
      @rdvs = @user.available_rdvs(current_organisation).page(filter_params[:page])
    end
    @rdvs = @rdvs.where(starts_at: date_range_params) if filter_params[:start].present? && filter_params[:end].present?
    @rdvs = @rdvs.includes(:motif).order(starts_at: :desc)
  end

  def show
    authorize(@rdv)
    respond_right_bar_with(@rdv)
  end

  def edit
    authorize(@rdv)
    respond_right_bar_with(@rdv)
  end

  def update
    authorize(@rdv)
    location = params[:callback_path].present? ? params[:callback_path] : @rdv.agenda_path_for_agent(current_agent)
    if @rdv.update(rdv_params)
      flash[:notice] = 'Le rendez-vous a été modifié.'
      redirect_to location.to_s
    else
      respond_right_bar_with @rdv, location: location.to_s
    end
  end

  def status
    authorize(@rdv)
    cancelled_at = ['unknown', 'waiting', 'seen'].include?(status_params[:status]) ? nil : Time.zone.now
    @rdv.update(status: status_params[:status], cancelled_at: cancelled_at)
    FileAttente.where(rdv_id: @rdv.id).delete_all
    respond_to do |f|
      f.js
    end
  end

  def destroy
    authorize(@rdv)
    location = callback_params[:callback_path] || @rdv.agenda_path_for_agent(current_agent)
    if @rdv.destroy
      flash[:notice] = "Le rendez-vous a été supprimé."
    else
      flash[:error] = "Une erreur s’est produite, le rendez-vous n’a pas pu être supprimé."
      Raven.capture_exception(Exception.new("Deletion failed for rdv : #{@rdv.id}"))
    end
    redirect_to location.to_s
  end

  private

  def set_rdv
    @rdv = Rdv.find(params[:id])
  end

  def rdv_params
    params.require(:rdv).permit(:location, :duration_in_min, :starts_at, agent_ids: [], user_ids: [])
  end

  def status_params
    params.require(:rdv).permit(:status)
  end

  def callback_params
    params.permit(:callback_path)
  end

  def date_range_params
    start_param = Date.parse(filter_params[:start])
    end_param = Date.parse(filter_params[:end])
    start_param..end_param
  end

  def filter_params
    params.permit(:organisation_id, :start, :end, :agent_id, :user_id, :page)
  end
end
