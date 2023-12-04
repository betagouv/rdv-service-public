class Agent::AdminPolicy < DefaultAgentPolicy
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

  def admin_of_record_organisation?
    current_agent.admin_orgs.include?(@record.organisation)
  end
end
