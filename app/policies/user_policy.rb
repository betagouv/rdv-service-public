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

  def edit?
    pro_and_belongs_to_record_organisation?
  end

  def update?
    pro_and_belongs_to_record_organisation?
  end

  def destroy?
    pro_and_belongs_to_record_organisation?
  end
end
