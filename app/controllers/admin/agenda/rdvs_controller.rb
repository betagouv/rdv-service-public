class Admin::Agenda::RdvsController < Admin::Agenda::BaseController
  def index
    agent = Agent.find(params[:agent_id])
    @organisation = Organisation.find(params[:organisation_id])
    @rdvs = policy_scope(Rdv, policy_scope_class: Agent::RdvPolicy::Scope)
      .merge(agent.rdvs)
      .includes(%i[organisation lieu motif users participations])
    @rdvs = @rdvs.where(starts_at: time_range_params)
    @rdvs = @rdvs.where(status: Rdv::NOT_CANCELLED_STATUSES) unless current_agent.display_cancelled_rdv
  end

  private

  def pundit_user
    current_agent
  end
end
