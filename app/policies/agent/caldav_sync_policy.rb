class Agent::CaldavSyncPolicy < ApplicationPolicy
  include CurrentAgentInPolicyConcern

  def current_agent?
    record == current_agent
  end

  alias show? current_agent?
  alias update? current_agent?
  alias destroy? current_agent?
end
