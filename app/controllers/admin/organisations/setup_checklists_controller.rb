class Admin::Organisations::SetupChecklistsController < AgentAuthController
  before_action :set_organisation

  def show
    authorize(@organisation)
    @lieux = Agent::LieuPolicy::Scope.apply(current_agent, current_organisation.lieux)
    @motifs = Agent::MotifPolicy::Scope.apply(current_agent, Motif).where(organisation: current_organisation)

    if current_agent.conseiller_numerique?
      render "show_conseiller_numerique"
    else
      @other_agents = policy_scope(Agent)
        .joins(:organisations).where(organisations: { id: current_organisation.id })
        .where.not(id: current_agent)
        .order_by_last_name

      render "show"
    end
  end
end
