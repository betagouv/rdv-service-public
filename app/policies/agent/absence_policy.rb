# frozen_string_literal: true

class Agent::AbsencePolicy < ApplicationPolicy
  include CurrentAgentInPolicyConcern

  def can_manage_agent?
    # delegate to AgentPolicy: if I can manage an agent, I can manage her absences
    ::Agent::AgentPolicy.new(pundit_user, record.agent).current_agent_or_admin_in_record_organisation?
  end

  alias show? can_manage_agent?
  alias create? can_manage_agent?
  alias cancel? can_manage_agent?
  alias new? can_manage_agent?
  alias update? can_manage_agent?
  alias edit? can_manage_agent?
  alias destroy? can_manage_agent?
  alias versions? can_manage_agent?

  class Scope < Scope
    include CurrentAgentInPolicyConcern

    def resolve
      # delegate to AgentPolicy: if I can manage an agent, I can manage her absences
      ::Agent::AgentPolicy::Scope.new(pundit_user, Agent.all).resolve
    end
  end
end
