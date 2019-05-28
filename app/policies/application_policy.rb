class ApplicationPolicy
  attr_reader :pro, :record

  def initialize(pro, record)
    @pro = pro
    @record = record
  end

  def user
    @pro
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

  class Scope
    attr_reader :pro, :scope

    def initialize(pro, scope)
      @pro = pro
      @scope = scope
    end

    def resolve
      scope.all
    end
  end
end
