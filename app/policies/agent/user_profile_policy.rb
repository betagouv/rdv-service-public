class Agent::UserProfilePolicy < DefaultAgentPolicy
  def create?
    same_org?
  end

  protected

  def same_org?
    if current_organisation.present?
      @record.organisation_id == current_organisation.id
    else
      current_agent.organisation_ids.include?(@record.organisation_id)
    end
  end

  class Scope < Scope
    def resolve
      scope.where(organisation_id: current_organisation&.id || current_agent.organisation_ids)
    end
  end
end
