# frozen_string_literal: true

class Agent::AbsencePolicy < ApplicationPolicy
  include CurrentAgentInPolicyConcern

  alias absence record

  def same_agent_or_has_access?
    return true if absence.agent_id == current_agent.id

    agents_i_can_handle.exists?(absence.agent_id)
  end

  alias show? same_agent_or_has_access?
  alias create? same_agent_or_has_access?
  alias cancel? same_agent_or_has_access?
  alias new? same_agent_or_has_access?
  alias update? same_agent_or_has_access?
  alias edit? same_agent_or_has_access?
  alias destroy? same_agent_or_has_access?
  alias versions? same_agent_or_has_access?

  class Scope < Scope
    include CurrentAgentInPolicyConcern

    def resolve
      if current_agent.service.secretariat?
        scope.where(agent: agents_of_my_orgs)
      else
        scope.where(agent: agents_i_can_handle + [current_agent.id])
      end
    end
  end
end
