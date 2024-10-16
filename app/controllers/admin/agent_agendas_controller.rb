class Admin::AgentAgendasController < AgentAuthController
  def show
    @hide_rdv_a_renseigner_in_main_layout = true
    @agent = Agent.find(params[:id])
    authorize(AgentAgenda.new(agent: @agent, organisation: current_organisation), policy_class: Agent::AgentAgendaPolicy)
    @status = params[:status]
    @organisation = current_organisation
    @selected_event_id = params[:selected_event_id]
    @date = params[:date].present? ? Date.parse(params[:date]) : nil
  end

  def toggle_displays
    @agent = current_agent
    authorize(@agent, policy_class: Agent::AgentPolicy)
    @agent.update!(agent_role_params)
    redirect_to admin_organisation_agent_agenda_path(params.permit(:status, :selected_event_id, :date))
  end

  private

  def agent_role_params
    params.require(:agent).permit(:display_saturdays, :display_cancelled_rdv)
  end
end
