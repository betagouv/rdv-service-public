class Rdv::ThirdStepPolicy < ApplicationPolicy
  def create?
    agent_and_belongs_to_record_organisation?
  end
end
