# frozen_string_literal: true

class Agent::OrganisationPolicy < DefaultAgentPolicy
  def link_to_organisation?
    current_agent.organisation_ids.include?(@record.id)
  end

  def new?
    current_agent.territorial_admin_in?(record.territory)
  end

  def create?
    current_agent.territorial_admin_in?(record.territory)
  end

  def destroy?
    false
  end

  def users?
    admin?
  end

  def rdvs?
    admin?
  end

  class Scope < Scope
    def resolve
      scope.merge(current_agent.organisations)
    end
  end
end
