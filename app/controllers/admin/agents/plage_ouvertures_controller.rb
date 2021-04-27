class Admin::Agents::PlageOuverturesController < ApplicationController
  include Admin::AuthenticatedControllerConcern
  respond_to :json

  def index
    agent = Agent.find(params[:agent_id])
    @organisation = Organisation.find(params[:organisation_id])
    @plage_ouverture_occurrences = custom_policy
      .includes(:lieu, :organisation)
      .where(expired_cached: false)
      .where(agent: agent)
      .all_occurences_for(date_range_params)
  end

  private

  # TODO: custom policy waiting for policies refactoring
  def custom_policy
    context = AgentContext.new(current_agent, @organisation)
    Agent::PlageOuverturePolicy::DepartementScope.new(context, PlageOuverture)
      .resolve
  end

  def date_range_params
    start_param = Date.parse(params[:start])
    end_param = Date.parse(params[:end])
    start_param..end_param
  end

  def pundit_user
    AgentContext.new(current_agent)
  end
end
