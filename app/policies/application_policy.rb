class ApplicationPolicy
  attr_reader :user_or_agent, :record

  def initialize(user_or_agent, record)
    @user_or_agent = user_or_agent
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  ## Agent helpers method
  def agent_and_belongs_to_record_organisation?
    if @record.is_a?(User)
      @user_or_agent.agent? && (@user_or_agent.organisation_ids & @record.organisation_ids).any?
    else
      @user_or_agent.agent? && @user_or_agent.organisation_ids.include?(@record.organisation_id)
    end
  end

  def record_belongs_to_agent?
    @user_or_agent.agent? && @user_or_agent.id == @record.agent_id
  end

  class Scope
    attr_reader :user_or_agent, :scope

    def initialize(user_or_agent, scope)
      @user_or_agent = user_or_agent
      @scope = scope
    end

    def resolve
      @user_or_agent.agent? ? scope.where(agent_id: @user_or_agent.id) : scope.none
    end
  end
end
