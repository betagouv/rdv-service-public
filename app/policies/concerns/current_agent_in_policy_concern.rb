# frozen_string_literal: true

module CurrentAgentInPolicyConcern
  extend ActiveSupport::Concern

  included do
    alias_method :context, :pundit_user
    delegate :agent, to: :context, prefix: :current # defines current_agent
  end

  private

  def agents_of_my_orgs
    Agent.in_orgs(current_agent.organisations)
  end

  def agents_i_can_handle
    ::Agent::AgentPolicy::Scope.new(pundit_user, Agent.all).resolve
  end
end
