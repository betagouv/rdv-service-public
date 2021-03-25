class Admin::Agents::AbsencesController < ApplicationController
  include Admin::AuthenticatedControllerConcern
  respond_to :json

  def index
    authorize_admin(current_agent)

    agent = Agent.find(params[:agent_id])
    @absence_occurrences = Admin::Occurrence.extract_from(policy_scope(Absence).includes(:organisation).where(agent: agent), date_range_params)
  end

  private

  def date_range_params
    start_param = Date.parse(params[:start])
    end_param = Date.parse(params[:end])
    start_param..end_param
  end

  def pundit_user
    AgentContext.new(current_agent)
  end
end
