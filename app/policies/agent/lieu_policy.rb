class Agent::LieuPolicy < Agent::AdminPolicy
  alias current_agent pundit_user

  def show?
    admin_of_record_organisation?
  end

  def create?
    admin_of_record_organisation?
  end

  def update?
    admin_of_record_organisation?
  end

  def destroy?
    admin_of_record_organisation?
  end

  def versions?
    admin_of_record_organisation?
  end

  class Scope < Scope
    alias current_agent pundit_user

    def resolve
      scope.where(organisation: current_agent.organisations)
    end
  end
end
