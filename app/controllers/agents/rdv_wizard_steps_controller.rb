class Agents::RdvWizardStepsController < AgentAuthController
  before_action :set_agent

  PERMITTED_PARAMS = [
    :motif_id, :duration_in_min, :starts_at, :lieu_id,
    :organisation_id, agent_ids: [], user_ids: []
  ].freeze

  def new
    @rdv_wizard = rdv_wizard_for(query_params)
    @rdv = @rdv_wizard.rdv
    skip_authorization
    render current_step
  end

  def create
    @rdv_wizard = rdv_wizard_for(rdv_params)
    @rdv = @rdv_wizard.rdv
    skip_authorization
    if @rdv_wizard.valid?
      redirect_to new_organisation_rdv_wizard_step_path(@rdv_wizard.to_query.merge(step: next_step_index))
    else
      render current_step
    end
  end

  protected

  def set_agent
    @agent = params[:agent_ids].present? ? Agent.find(params[:agent_ids].first) : current_agent
  end

  def current_step
    return AgentRdvWizard::STEPS.first if params[:step].blank?

    step = "step#{params[:step]}"
    raise InvalidStep unless step.in?(AgentRdvWizard::STEPS)

    step
  end

  def next_step_index
    AgentRdvWizard::STEPS.index(current_step) + 2 # steps start at 1 + increment
  end

  def rdv_wizard_for(request_params)
    klass = "AgentRdvWizard::#{current_step.camelize}".constantize
    klass.new(current_agent, current_organisation, request_params)
  end

  def rdv_params
    params.require(:rdv).permit(PERMITTED_PARAMS)
  end

  def query_params
    params.permit(PERMITTED_PARAMS)
  end
end
