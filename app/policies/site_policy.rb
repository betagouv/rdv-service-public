class SitePolicy < ApplicationPolicy
  def new?
    @pro.admin?
  end

  def create?
    admin_and_has_site?
  end

  def edit?
    admin_and_has_site?
  end

  def update?
    admin_and_has_site?
  end

  private

  def admin_and_has_site?
    @pro.admin? && @record.in?(@pro.sites)
  end
end
