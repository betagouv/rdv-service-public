# frozen_string_literal: true

class Agent::AbsencePolicy < ApplicationPolicy
  include CurrentAgentInPolicyConcern

  # delegate to AgentPolicy: if I can manage an agent, I can manage her absences
  delegate :can_manage_agent?, to: :agent_policy

  alias show? can_manage_agent?
  alias create? can_manage_agent?
  alias cancel? can_manage_agent?
  alias new? can_manage_agent?
  alias update? can_manage_agent?
  alias edit? can_manage_agent?
  alias destroy? can_manage_agent?
  alias versions? can_manage_agent?

  private

  def agent_policy
    ::Agent::AgentPolicy.new(pundit_user, record.agent)
  end

  class Scope < Scope
    include CurrentAgentInPolicyConcern

    # delegate to AgentPolicy: if I can manage an agent, I can manage her absences
    delegate :resolve, to: :agent_policy

    private

    def agent_policy
      ::Agent::AgentPolicy::Scope.new(pundit_user, Agent.all)
    end
  end
end
