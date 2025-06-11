class Admin::Planning::AgendasController < AgentAuthController
  include Admin::Planning::SetAgentsConcern

  def show
    set_agents
    @show_agent_select = true
    @agents.each do |agent|
      authorize(AgentAgenda.new(agent:, organisation: current_organisation), policy_class: Agent::AgentAgendaPolicy)
    end

    if @agents.size > 1
      render :multi_agents_agenda and return
    end

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
