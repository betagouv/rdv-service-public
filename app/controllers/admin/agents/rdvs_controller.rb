class Admin::Agents::RdvsController < ApplicationController
  include Admin::AuthenticatedControllerConcern
  respond_to :json

  def index
    authorize_admin(current_agent)

    agent = Agent.find(params[:agent_id])
    @organisation = Organisation.find(params[:organisation_id])
    @rdvs = policy_scope(Rdv).with_agent(agent)
  end

  private

  def pundit_user
    AgentContext.new(current_agent)
  end
end
