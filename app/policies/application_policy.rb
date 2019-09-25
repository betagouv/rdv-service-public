class ApplicationPolicy
  attr_reader :user_or_pro, :record

  def initialize(user_or_pro, record)
    @user_or_pro = user_or_pro
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

  ## Pro helpers method
  def pro_and_belongs_to_record_organisation?
    @user_or_pro.pro? && @user_or_pro.organisation_id == @record.organisation_id
  end

  def record_belongs_to_pro?
    @user_or_pro.pro? && @user_or_pro.id == @record.pro_id
  end

  class Scope
    attr_reader :user_or_pro, :scope

    def initialize(user_or_pro, scope)
      @user_or_pro = user_or_pro
      @scope = scope
    end

    def resolve
      @user_or_pro.pro? ? scope.where(organisation_id: @user_or_pro.organisation_id) : []
    end
  end
end
