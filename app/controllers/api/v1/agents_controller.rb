class Api::V1::AgentsController < Api::V1::AgentAuthBaseController
  def index
    agents = policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope).distinct
    agents = agents.joins(:organisations).where(organisations: { id: current_organisation.id }) if current_organisation.present?
    render_collection(agents.order(:created_at))
  end

  def create
    organisations = Organisation.where(id: params[:organisation_ids])

    authorize(Agent.new(organisations:), policy_class: Agent::AgentPolicy)

    create_agent = AdminCreatesAgent.new(
      agent_params: params.permit(:email),
      current_agent: current_agent,
      organisations:,
      access_level: params.require(:access_level)
    )

    @agent = create_agent.call

    if @agent.valid?
      render_record @agent
    else
      render status: :unprocessable_entity, json: { error_messages: @agent.errors.full_messages }
    end
  end

  def me
    render_record current_agent
  end
end
