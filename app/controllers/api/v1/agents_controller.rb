class Api::V1::AgentsController < Api::V1::AgentAuthBaseController
  def index
    agents = policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope).distinct
    agents = agents.joins(:organisations).where(organisations: { id: current_organisation.id }) if current_organisation.present?
    render_collection(agents.order(:created_at))
  end
end
