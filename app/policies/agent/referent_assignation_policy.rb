# frozen_string_literal: true

class Agent::ReferentAssignationPolicy < DefaultAgentPolicy
  def create?
    same_agent_territory? && same_user_org?
  end
  alias show? create?
  alias destroy? create?

  protected

  def same_agent_territory?
    if current_organisation.present?
      @record.agent.organisations.map(&:territory_id).include? current_organisation.territory_id
    else
      (@record.agent.organisations.map(&:territory_id) & current_agent.organisations.map(&:territory_id)).any?
    end
  end

  def same_user_org?
    if current_organisation.present?
      @record.user.organisation_ids.include?(current_organisation.id)
    else
      (@record.user.organisation_ids & current_agent.organisation_ids).any?
    end
  end
end
