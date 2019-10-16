class AgentPolicy < AdminPolicy
  def show?
    same_or_admin?
  end

  def edit?
    same_or_admin?
  end

  def destroy?
    same_or_admin?
  end

  def invite?
    create?
  end

  def reinvite?
    invite?
  end

  private

  def same_or_admin?
    @agent == @record || admin_and_belongs_to_record_organisation?
  end
end
