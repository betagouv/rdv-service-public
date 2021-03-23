class Admin::Agents::AbsencesController < ApplicationController
  include Admin::AuthenticatedControllerConcern

  def index
    authorize_admin(current_agent)

    agent = Agent.find(params[:agent_id])
    @absence_occurrences = Admin::Occurrence.extract_from(Absence.with_agent(agent), date_range_params)
    respond_to :json
  end

  def date_range_params
    start_param = Date.parse(filter_params[:start])
    end_param = Date.parse(filter_params[:end])
    start_param..end_param
  end

  def filter_params
    params.permit(:start, :end, :organisation_id, :agent_id, :page, :current_tab)
  end

  def pundit_user
    AgentContext.new(current_agent)
  end
end
