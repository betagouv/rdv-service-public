class OrganisationPolicy < ApplicationPolicy
  def show?
    true
  end

  def edit?
    admin_belongs_to_organisation?
  end

  def update?
    admin_belongs_to_organisation?
  end

  private

  def admin_belongs_to_organisation?
    @pro.admin? && @pro.organisation_id == @record.id
  end
end
