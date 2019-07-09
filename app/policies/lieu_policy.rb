class LieuPolicy < ApplicationPolicy
  def new?
    @pro.admin?
  end

  def create?
    admin_and_belongs_to_lieu_organisation?
  end

  def edit?
    admin_and_belongs_to_lieu_organisation?
  end

  def update?
    admin_and_belongs_to_lieu_organisation?
  end

  def destroy?
    admin_and_belongs_to_lieu_organisation?
  end

  private

  def admin_and_belongs_to_lieu_organisation?
    @pro.admin? && @pro.organisation_id == @record.organisation_id
  end
end
