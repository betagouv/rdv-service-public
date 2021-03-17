class Admin::Agents::PlageOuverturesController < ApplicationController
  include Admin::AuthenticatedControllerConcern

  def index
    authorize_admin(current_agent)

    agent = Agent.find(params[:agent_id])
    @organisation = Organisation.find(params[:organisation_id])
    @plage_ouverture_occurences = extract_occurence_from(PlageOuverture.with_agent(agent))
  end

  def extract_occurence_from(plage_ouvertures)
    plage_ouvertures.flat_map { |po| po.occurences_for(date_range_params).map { |occurence| [po, occurence] } }.sort_by(&:second)
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
