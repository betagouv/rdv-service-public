class Admin::RdvWizardStepsController < AgentAuthController
  before_action :set_agent

  PERMITTED_PARAMS = [
    :motif_id, :duration_in_min, :starts_at, :lieu_id, :context, :service_id,
    :organisation_id, :active_warnings_confirm_decision,
    { agent_ids: [], user_ids: [] }
  ].freeze

  def new
    @rdv_wizard = rdv_wizard_for(query_params)
    @rdv = @rdv_wizard.rdv
    set_services_and_motifs if current_step == "step1"
    authorize(@rdv_wizard.rdv, :new?)
    render current_step
  end

  def create
    @rdv_wizard = rdv_wizard_for(rdv_params)
    @rdv = @rdv_wizard.rdv
    set_services_and_motifs if current_step == "step1"
    authorize(@rdv_wizard.rdv, :create?)
    if @rdv_wizard.save
      redirect_to @rdv_wizard.success_path, @rdv_wizard.success_flash
    else
      render current_step
    end
  end

  protected

  def set_agent
    @agent = params[:agent_ids].present? ? Agent.find(params[:agent_ids].first) : current_agent
  end

  def current_step
    return Admin::RdvWizardForm::STEPS.first if params[:step].blank?

    step = "step#{params[:step]}"
    raise InvalidStep unless step.in?(Admin::RdvWizardForm::STEPS)

    step
  end

  def rdv_wizard_for(request_params)
    klass = "Admin::RdvWizardForm::#{current_step.camelize}".constantize
    klass.new(current_agent, current_organisation, request_params)
  end

  def set_services_and_motifs
    @motifs = policy_scope(Motif).available_motifs_for_organisation_and_agent(current_organisation, @agent)
    @services = policy_scope(Service).where(id: @motifs.pluck(:service_id).uniq)
    @rdv_wizard.service_id = @services.first.id if @services.count == 1
  end

  def rdv_params
    params.require(:rdv).permit(PERMITTED_PARAMS)
  end

  def query_params
    params.permit(PERMITTED_PARAMS)
  end
end
