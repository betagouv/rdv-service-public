class UserPolicy < ApplicationPolicy
  def show?
    pro_and_belongs_to_record_organisation?
  end

  def create?
    pro_and_belongs_to_record_organisation?
  end

  def invite?
    @user_or_pro.pro?
  end

  def update?
    if @user_or_pro.pro?
      pro_and_belongs_to_record_organisation?
    elsif @user_or_pro.user?
      @record.id == @user_or_pro.id
    end
  end

  def destroy?
    pro_and_belongs_to_record_organisation?
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
