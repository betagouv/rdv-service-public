class Agent::OrganisationPolicy < ApplicationPolicy
  def in_organisation?
    current_agent.organisation_ids.include?(@record.id)
  end

  def admin_in_organisation?
    current_agent.admin_in_organisation?(record)
  end

  def territorial_admin?
    current_agent.territorial_admin_in?(record.territory)
  end

  alias show? in_organisation?
  alias creneau_availability? in_organisation?

  alias edit? admin_in_organisation?
  alias update? admin_in_organisation?
  alias versions? admin_in_organisation?

  alias new? territorial_admin?
  alias create? territorial_admin?
  alias close? territorial_admin?
  alias reopen? territorial_admin?

  alias current_agent pundit_user

  def destroy?
    false
  end

  class Scope < Scope
    def resolve
      scope.merge(current_agent.organisations)
    end

    alias current_agent pundit_user
  end
end
