class Admin::Planning::AgendasController < AgentAuthController
  include Admin::Planning::SetAgentsConcern

  def show
    set_agents

    @agents.each do |agent|
      authorize(AgentAgenda.new(agent:, organisation: current_organisation), policy_class: Agent::AgentAgendaPolicy)
    end

    # À l’arrivée du multi-agent, on affichera une nouvelle vue
    # En attendant, on redirige vers la page d’accueil si plusieurs agents sont sélectionnés (ce qui ne devrait pas arriver sauf si quelqu’un a modifié l’URL à la main)
    if @agents.size > 1
      redirect_to root_path and return
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
