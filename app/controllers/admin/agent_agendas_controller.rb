# frozen_string_literal: true

class Admin::AgentAgendasController < AgentAuthController
  def show
    @agent = policy_scope(Agent).find(params[:id])
    authorize(AgentAgenda.new(agent: @agent, organisation: current_organisation))
    @status = params[:status]
    @organisation = current_organisation
    @selected_event_id = params[:selected_event_id]
    @date = params[:date].present? ? Date.parse(params[:date]) : nil
  end
end
