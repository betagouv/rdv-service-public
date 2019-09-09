class AbsencePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(pro_id: pro.id)
    end
  end

  def index?
    true
  end

  def new?
    true
  end

  def create?
    belongs_to_organisation_and_pro?
  end

  def edit?
    belongs_to_organisation_and_pro?
  end

  def update?
    belongs_to_organisation_and_pro?
  end

  def destroy?
    belongs_to_organisation_and_pro?
  end

  private

  def belongs_to_organisation_and_pro?
    @pro.organisation_id == @record.organisation_id && @pro.id == @record.pro_id
  end
end
