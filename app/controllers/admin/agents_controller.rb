class Admin::AgentsController < AgentAuthController
  respond_to :html, :json

  def index
    agents = policy_scope(Agent).active.order_by_last_name
    @invited_agents = agents.invitation_not_accepted.created_by_invite
    @complete_agents = params[:search].present? ? agents.search_by_text(params[:search]) : agents
    @complete_agents = @complete_agents.complete.includes(:service).page(params[:page])
  end

  def show
    @agent = policy_scope(Agent).find(params[:id])
    authorize(@agent)
    @status = params[:status]
    @organisation = current_organisation
    @selected_event_id = params[:selected_event_id]
    @date = params[:date].present? ? Date.parse(params[:date]) : nil
  end

  def destroy
    @agent = policy_scope(Agent).find(params[:id])
    authorize(@agent)
    flash[:notice] = "L'utilisateur a été supprimé." if @agent.soft_delete current_organisation
    respond_right_bar_with @agent, location: admin_organisation_agents_path(current_organisation)
  end

  def reinvite
    @agent = policy_scope(Agent).find(params[:id])
    authorize(@agent)
    @agent.invite!
    respond_to do |f|
      f.html { redirect_to admin_organisation_agents_path(current_organisation), notice: "L'agent a été réinvité." }
      f.js
    end
  end
end
