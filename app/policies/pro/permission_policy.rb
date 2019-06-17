class Pro::PermissionPolicy < ApplicationPolicy
  def update?
    admin_belongs_to_same_organisation
  end

  private

  def admin_belongs_to_same_organisation
    @pro.admin? && @pro.organisation_id == @record.pro.organisation_id
  end

  def same_pro
    @pro == @record.pro
  end
end
