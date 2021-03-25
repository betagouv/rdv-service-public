class Admin::Agents::PlageOuverturesController < ApplicationController
  include Admin::AuthenticatedControllerConcern
  respond_to :json

  def index
    authorize_admin(current_agent)

    agent = Agent.find(params[:agent_id])
    @organisation = Organisation.find(params[:organisation_id])
    @plage_ouverture_occurences = Admin::Occurrence.extract_from(policy_scope(PlageOuverture).includes(:lieu, :oranisation).where(expired_cached: false).where(agent: agent), date_range_params)
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
