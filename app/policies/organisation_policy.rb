class OrganisationPolicy < AdminPolicy
  def destroy?
    false
  end

  class Scope
    attr_reader :user_or_pro, :scope

    def initialize(user_or_pro, scope)
      @user_or_pro = user_or_pro
      @scope = scope
    end

    def resolve
      @user_or_pro.pro? && @user_or_pro.admin? ? scope.where(id: @user_or_pro.organisation_id) : []
    end
  end
end
