class Admin::AgentAgendasController < ApplicationController
  include Admin::AuthenticatedControllerConcern

  def show
    @organisation = Organisation.find(params[:organisation_id])
    @agent = policy_scope_admin(Agent).find(params[:id])
    authorize_admin(AgentAgenda.new(agent: @agent, organisation: @organisation))
    @status = params[:status]
    @selected_event_id = params[:selected_event_id]
    @date = params[:date].present? ? Date.parse(params[:date]) : nil
  end

  def pundit_user
    AgentContext.new(current_agent)
  end
end
