class Agents::AgentsController < AgentAuthController
  respond_to :json

  def search
    term = params[:term].presence
    organisation_id = params[:organisation_id].presence

    skip_authorization
    @agents = policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope)
      .active
      .select(:id, :email, :first_name, :last_name)
    @agents = @agents.joins(:roles).where(roles: { organisation_id: }) if organisation_id
    @agents = term ? @agents.search_by_text(term) : @agents.ordered_by_last_name

    # la jointure peut créer des doublons, et impossible d'utiliser DISTINCT avec pg_search
    @agents = @agents.load.uniq
  end
end
