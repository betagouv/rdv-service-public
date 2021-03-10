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
      scope.where(organisation: current_organisation)
    end
  end

  protected

  def same_org?
    @record.organisation == current_organisation
  end
end
