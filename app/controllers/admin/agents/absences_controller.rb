class Admin::Agents::AbsencesController < ApplicationController
  include Admin::AuthenticatedControllerConcern

  def index
    authorize_admin(current_agent)

    agent = Agent.find(params[:agent_id])
    @absence_occurrences = extract_occurrence_from(Absence.with_agent(agent))
  end

  def extract_occurrence_from(absences)
    absences.flat_map { |absence| absence.occurences_for(date_range_params).map { |occurrence| [absence, occurrence] } }.sort_by(&:second)
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
