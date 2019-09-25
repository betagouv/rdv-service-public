class AdminPolicy < ApplicationPolicy
  def show?
    pro_and_admin?
  end

  def new?
    pro_and_admin?
  end

  def create?
    pro_and_admin?
  end

  def edit?
    admin_and_belongs_to_record_organisation?
  end

  def update?
    admin_and_belongs_to_record_organisation?
  end

  def destroy?
    admin_and_belongs_to_record_organisation?
  end

  def pro_and_admin?
    @user_or_pro.pro? && @user_or_pro.admin?
  end

  def admin_and_belongs_to_record_organisation?
    if @record.is_a? Organisation
      pro_and_admin? && @user_or_pro.organisation_id == @record.id
    else
      pro_and_admin? && @user_or_pro.organisation_id == @record.organisation_id
    end
  end

  class Scope
    attr_reader :user_or_pro, :scope

    def initialize(user_or_pro, scope)
      @user_or_pro = user_or_pro
      @scope = scope
    end

    def pro_and_admin?
      @user_or_pro.pro? && @user_or_pro.admin?
    end

    def resolve
      pro_and_admin? ? scope.where(organisation_id: @user_or_pro.organisation_id) : []
    end
  end
end
