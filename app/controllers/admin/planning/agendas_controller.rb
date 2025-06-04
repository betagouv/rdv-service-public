class Admin::Planning::AgendasController < AgentAuthController
  def show
    @show_agent_select = true
    @agent = params[:agent_id].present? ? Agent.find(params[:agent_id]) : current_agent
    authorize(AgentAgenda.new(agent: @agent, organisation: current_organisation), policy_class: Agent::AgentAgendaPolicy)
    @status = params[:status]
    @organisation = current_organisation
    @selected_event_id = params[:selected_event_id]
    @date = params[:date].present? ? Date.parse(params[:date]) : nil
  end

  def toggle_displays
    authorize(current_agent, policy_class: Agent::AgentPolicy)
    current_agent.update!(permitted_agent_params)
    redirect_back fallback_location: admin_organisation_planning_agenda_path(current_organisation)
  end

  private

  def permitted_agent_params
    params.require(:agent).permit(:display_saturdays, :display_cancelled_rdv)
  end
end
