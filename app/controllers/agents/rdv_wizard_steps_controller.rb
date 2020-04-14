class Agents::RdvWizardStepsController < AgentAuthController
  layout 'application-small'
  before_action :set_agent

  PERMITTED_PARAMS = [
    :motif_id, :duration_in_min, :starts_at, :location, :notes,
    :organisation_id, agent_ids: [], user_ids: []
  ].freeze

  def new
    @rdv_wizard = rdv_wizard_for(query_params)
    @rdv = @rdv_wizard.rdv
    @agents_authorize = agents_authorized if current_step == 'step2'
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
    return RdvWizard::STEPS.first if params[:step].blank?

    step = "step#{params[:step]}"
    raise InvalidStep unless step.in?(RdvWizard::STEPS)

    step
  end

  def next_step_index
    RdvWizard::STEPS.index(current_step) + 2 # steps start at 1 + increment
  end

  def rdv_wizard_for(request_params)
    klass = "RdvWizard::#{current_step.camelize}".constantize
    klass.new(current_agent, current_organisation, request_params)
  end

  def agents_authorized
    return [] if @rdv_wizard.motif.nil?

    agents = @rdv_wizard.motif.service.agents.complete.active.joins(:organisations).where(organisations: { id: current_organisation.id })
    agents += current_organisation.agents.complete.active.includes(:service).secretariat if @rdv_wizard.motif.for_secretariat
    agents
  end

  def rdv_params
    params.require(:rdv).permit(PERMITTED_PARAMS).merge(params.permit(:plage_ouverture_location))
  end

  def query_params
    params.permit(:plage_ouverture_location, *PERMITTED_PARAMS)
  end
end
