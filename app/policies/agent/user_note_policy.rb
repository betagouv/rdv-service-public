class Agent::UserNotePolicy < DefaultAgentPolicy
  def index?
    same_org?
  end

  def create?
    same_org?
  end

  def destroy?
    same_org?
  end

  class Scope < Scope
    def resolve
      scope.joins(:organisations).where(organisations: { id: @context.organisation.id })
    end
  end

  protected

  def same_org?
    @record.organisation == @context.organisation
  end
end
