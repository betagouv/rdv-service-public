class Admin::Agents::RdvsController < ApplicationController
  include Admin::AuthenticatedControllerConcern
  respond_to :json

  def index
    agent = Agent.find(params[:agent_id])
    @organisation = Organisation.find(params[:organisation_id])
    @rdvs = custom_policy.with_agent(agent).includes(%i[organisation lieu motif users])
  end

  private

  # TODO: custom policy waiting for policies refactoring
  def custom_policy
    context = AgentContext.new(current_agent, @organisation)
    Agent::RdvPolicy::DepartementScope.new(context, Rdv)
      .resolve
  end

  def pundit_user
    AgentContext.new(current_agent)
  end
end
