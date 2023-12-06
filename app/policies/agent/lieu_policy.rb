class Agent::LieuPolicy < ApplicationPolicy
  alias current_agent pundit_user

  def update?
    admin_of_record_organisation?
  end

  alias new? update?
  alias create? update?
  alias edit? update?
  alias destroy? update?
  alias versions? update?

  private

  def admin_of_record_organisation?
    current_agent.admin_orgs.include?(@record.organisation)
  end

  class Scope < Scope
    alias current_agent pundit_user

    def resolve
      scope.where(organisation: current_agent.organisations)
    end
  end
end
