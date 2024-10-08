class ApplicationPolicy
  attr_reader :pundit_user, :record

  def initialize(pundit_user, record)
    @pundit_user = pundit_user
    @record = record
  end

  class Scope
    attr_reader :pundit_user, :scope

    def initialize(pundit_user, scope)
      @pundit_user = pundit_user
      @scope = scope
    end

    def self.apply(pundit_user, scope)
      new(pundit_user, scope).resolve
    end
  end
end
