class Agents::RdvsController < AgentAuthController
  respond_to :html, :json

  before_action :set_rdv, except: [:index, :create]

  def index
    @rdvs = policy_scope(Rdv)
    @agent = policy_scope(Agent).find(filter_params[:agent_id])
    @rdvs = @rdvs.joins(:agents).where(agents: { id: @agent })
    @rdvs = @rdvs.default_stats_period if filter_params[:default_period].present?
    @rdvs = @rdvs.status(filter_params[:status]) if filter_params[:status].present?
    @rdvs = @rdvs.where(starts_at: date_range_params) if filter_params[:start].present? && filter_params[:end].present?
    @rdvs = @rdvs.includes(:organisation, :motif, :agents_rdvs, agents: :service).order(starts_at: :desc)
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
    flash[:notice] = 'Le rendez-vous a été modifié.' if @rdv.update(rdv_params)
    respond_right_bar_with @rdv, location: callback_path(@rdv)
  end

  def status
    authorize(@rdv)
    cancelled_at = ['unknown', 'waiting', 'seen'].include?(status_params[:status]) ? nil : Time.zone.now
    @rdv.update(status: status_params[:status], cancelled_at: cancelled_at)
    @rdv.file_attentes.delete_all
    respond_to do |f|
      f.js
    end
  end

  def destroy
    authorize(@rdv)
    redirect_location = callback_path(@rdv)
    if @rdv.destroy
      flash[:notice] = "Le rendez-vous a été supprimé."
    else
      flash[:error] = "Une erreur s’est produite, le rendez-vous n’a pas pu être supprimé."
      Raven.capture_exception(Exception.new("Deletion failed for rdv : #{@rdv.id}"))
    end
    redirect_to redirect_location
  end

  def create
    @rdv = Rdv.new(rdv_params)
    @rdv.organisation = current_organisation
    authorize(@rdv)
    if @rdv.save
      redirect_to @rdv.agenda_path_for_agent(current_agent), notice: "Le rendez-vous a été créé."
    else
      render 'agents/rdv_wizard_steps/step3', layout: 'application-small'
    end
  end

  private

  def set_rdv
    @rdv = Rdv.find(params[:id])
  end

  def callback_path(rdv)
    location = params[:callback_path].present? ? params[:callback_path] : rdv.agenda_path_for_agent(current_agent)
    location.to_s
  end

  def rdv_params
    params.require(:rdv).permit(:motif_id, :location, :duration_in_min, :starts_at, :notes, agent_ids: [], user_ids: [])
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
    params.permit(:organisation_id, :start, :end, :agent_id, :user_id, :page, :status, :default_period)
  end
end
