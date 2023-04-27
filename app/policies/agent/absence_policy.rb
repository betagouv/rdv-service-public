# frozen_string_literal: true

class Agent::AbsencePolicy < ApplicationPolicy
  include CurrentAgentInPolicyConcern

  # Règle métier : on peut gérer une absence si on peut voir l'agent auquel elle appartient.
  def can_manage_absence?
    ::Agent::AgentPolicy::Scope.new(pundit_user, Agent.all).resolve.exists?(record.agent_id)
  end

  alias show? can_manage_absence?
  alias create? can_manage_absence?
  alias cancel? can_manage_absence?
  alias new? can_manage_absence?
  alias update? can_manage_absence?
  alias edit? can_manage_absence?
  alias destroy? can_manage_absence?
  alias versions? can_manage_absence?

  class Scope < Scope
    include CurrentAgentInPolicyConcern

    # Même règle métier : on peut gérer, donc lister, les absences si
    # on peut voir les agents auquel elles appartiennent.
    def resolve
      agents_i_can_see = ::Agent::AgentPolicy::Scope.new(pundit_user, Agent.all).resolve
      scope.where(agent: agents_i_can_see)
    end
  end
end
