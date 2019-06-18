class Rdv::ThirdStepPolicy < ApplicationPolicy
  def new?
    true
  end

  def create?
    belongs_to_organisation?
  end

  private

  def belongs_to_organisation?
    @pro.organisation_id == @record.organisation.id
  end
end
