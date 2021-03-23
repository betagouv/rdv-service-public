class Admin::Agents::RdvsController < ApplicationController
  include Admin::AuthenticatedControllerConcern

  def index
    authorize_admin(current_agent)

    agent = Agent.find(params[:agent_id])
    @organisation = Organisation.find(params[:organisation_id])
    @rdvs = Rdv.with_agent(agent)
    respond_to :json
  end

  def pundit_user
    AgentContext.new(current_agent)
  end
end
