class Agent::UserProfilePolicy < DefaultAgentPolicy
  def create?
    same_org?
  end

  protected

  def same_org?
    if @context.organisation.present?
      @record.organisation_id == @context.organisation.id
    else
      @context.agent.organisation_ids.include?(@record.organisation_id)
    end
  end

  class Scope < Scope
    def resolve
      scope.where(organisation_id: @context.organisation&.id || @context.agent.organisation_ids)
    end
  end
end
