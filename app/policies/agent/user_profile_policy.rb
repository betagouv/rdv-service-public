# frozen_string_literal: true

class Agent::UserProfilePolicy < DefaultAgentPolicy
  def create?
    same_territory?
  end

  def destroy?
    current_agent.organisation_ids.include?(@record.organisation_id)
  end

  protected

  def same_territory?
    if current_organisation.present?
      @record.territory_id == current_organisation.territory_id
    else
      current_agent.organisations.map(&:territory_id).include?(@record.territory_id)
    end
  end

  class Scope < Scope
    def resolve
      scope.where(organisation_id: current_organisation&.id || current_agent.organisation_ids)
    end
  end
end
