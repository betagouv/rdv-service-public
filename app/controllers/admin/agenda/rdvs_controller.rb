class Admin::Agenda::RdvsController < Admin::Agenda::FullCalendarController
  def index
    agent = Agent.find(params[:agent_id])
    @organisation = Organisation.find(params[:organisation_id])
    @rdvs = custom_policy
      .merge(agent.rdvs)
      .includes(%i[organisation lieu motif users participations])
    @rdvs = @rdvs.where(starts_at: date_range_params) if date_range_params.present?
    @rdvs = @rdvs.where(status: Rdv::NOT_CANCELLED_STATUSES) unless current_agent.display_cancelled_rdv
  end

  private

  # TODO: custom policy waiting for policies refactoring
  def custom_policy
    context = AgentOrganisationContext.new(current_agent, @organisation)
    Agent::RdvPolicy::DepartementScope.new(context, Rdv)
      .resolve
  end
end
