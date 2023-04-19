# frozen_string_literal: true

class Agent::AbsencePolicy < ApplicationPolicy
  include CurrentAgentInPolicyConcern

  def can_manage_absence?
    agent_policy.can_manage_agent? || same_service_and_org_in_common?
  end

  alias show? can_manage_absence?
  alias create? can_manage_absence?
  alias cancel? can_manage_absence?
  alias new? can_manage_absence?
  alias update? can_manage_absence?
  alias edit? can_manage_absence?
  alias destroy? can_manage_absence?
  alias versions? can_manage_absence?

  private

  def same_service_and_org_in_common?
    ___
  end

  def agent_policy
    ::Agent::AgentPolicy.new(pundit_user, record.agent)
  end

  class Scope < Scope
    include CurrentAgentInPolicyConcern

    # delegate to AgentPolicy: if I can manage an agent, I can manage her absences
    def resolve
      agents_i_can_manage = agent_policy.resolve
      scope.where(agent: agents_i_can_manage)
    end

    private

    def agent_policy
      ::Agent::AgentPolicy::Scope.new(pundit_user, Agent.all)
    end
  end
end
