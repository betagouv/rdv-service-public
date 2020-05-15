class Agents::RdvsController < AgentAuthController
  respond_to :html, :json

  before_action :set_rdv, except: [:index, :create]

  def index
    @agent = policy_scope(Agent).find(filter_params[:agent_id])
    @form = AgentRdvSearchForm.new(filter_params)
    @rdvs = rdvs_list(@agent, @form)
  end

  def show
    @uncollapsed_section = params[:uncollapsed_section]
    authorize(@rdv)
  end

  def edit
    authorize(@rdv)
    respond_right_bar_with(@rdv)
  end

  def update
    authorize(@rdv)
    @rdv.updated_at = Time.zone.now
    # TODO: replace this manual touch. It forces creating a version when an
    # agent or a user is removed from the RDV. the touch: true option on the
    # association does not do it for some reason I could not figure out
    if params[:status] == 'excused'
      CancelRdvByAgentService.new(@rdv).perform
      flash[:notice] = 'Le rendez-vous a été annulé.'
    elsif @rdv.update(rdv_params)
      flash[:notice] = 'Le rendez-vous a été modifié.'
    end
    respond_right_bar_with @rdv, location: request.referer
  end

  def status
    # TODO: remove this route and use #update
    authorize(@rdv)
    cancelled_at = ['unknown', 'waiting', 'seen'].include?(status_params[:status]) ? nil : Time.zone.now
    @rdv.update(status: status_params[:status], cancelled_at: cancelled_at)
    @rdv.file_attentes.delete_all
    flash[:notice] = "Le statut du RDV a été modifié"
    redirect_to organisation_rdv_path(@rdv.organisation, @rdv)
  end

  def destroy
    authorize(@rdv)
    if @rdv.destroy
      flash[:notice] = "Le rendez-vous a été supprimé."
    else
      flash[:error] = "Une erreur s’est produite, le rendez-vous n’a pas pu être supprimé."
      Raven.capture_exception(Exception.new("Deletion failed for rdv : #{@rdv.id}"))
    end
    redirect_to organisation_agent_path(current_organisation, current_agent)
  end

  def create
    @rdv = Rdv.new(rdv_params)
    @rdv.organisation = current_organisation
    authorize(@rdv)
    if @rdv.save
      redirect_to @rdv.agenda_path_for_agent(current_agent), notice: "Le rendez-vous a été créé."
    else
      @rdv_wizard = RdvWizard::Step3.new(current_agent, current_organisation, @rdv.attributes)
      render 'agents/rdv_wizard_steps/step3', layout: 'application-small'
    end
  end

  private

  def set_rdv
    @rdv = Rdv.find(params[:id])
  end

  def rdv_params
    params.require(:rdv).permit(:motif_id, :location, :duration_in_min, :starts_at, :notes, agent_ids: [], user_ids: [])
  end

  def status_params
    params.require(:rdv).permit(:status)
  end

  def filter_params
    params.permit(:organisation_id, :start, :end, :date, :agent_id, :user_id, :page, :status, :default_period, :show_user_details)
  end

  def rdvs_list(agent, form)
    rdvs = agent.rdvs.where(organisation: current_organisation)
    rdvs = rdvs.default_stats_period if form.default_period.present?
    rdvs = rdvs.status(form.status) if form.status.present?
    if form.date_range_params.present?
      rdvs = rdvs.where(starts_at: form.date_range_params)
    elsif form.date.present?
      rdvs = rdvs.where("DATE(starts_at) = ?", form.date)
    end
    rdvs = rdvs.includes(:organisation, :motif, :agents_rdvs, agents: :service).order(starts_at: :desc)
    rdvs
  end
end
