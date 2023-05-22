# frozen_string_literal: true

class Agent::OrganisationPolicy < DefaultAgentPolicy
  def link_to_organisation?
    current_agent.organisation_ids.include?(@record.id)
  end

  def admin_in_record_organisation?
    current_agent.roles.level_admin.pluck(:organisation_id).include?(record.id)
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

  def versions?
    admin?
  end

  def update?
    admin_in_record_organisation?
  end

  def show?
    link_to_organisation?
  end

  class Scope < Scope
    def resolve
      scope.merge(current_agent.organisations)
    end
  end
end
