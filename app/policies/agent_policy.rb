class AgentPolicy < AdminPolicy
  class Scope
    attr_reader :user_or_agent, :scope

    def initialize(user_or_agent, scope)
      @user_or_agent = user_or_agent
      @scope = scope
    end

    def resolve
      @user_or_agent.agent? ? scope.joins(:organisations).where(organisations: { id: @user_or_agent.organisation_ids }) : scope.none
    end
  end

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
