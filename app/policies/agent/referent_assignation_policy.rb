# Cette policy n'est utilisée que par l'API,
# voir https://github.com/betagouv/rdv-solidarites.fr/pull/3138
class Agent::ReferentAssignationPolicy < DefaultAgentPolicy
  def create?
    same_agent_territory? && same_user_org?
  end
  alias destroy? create?

  protected

  def same_agent_territory?
    @record.agent.organisations.map(&:territory_id).intersect?(current_agent.organisations.map(&:territory_id))
  end

  def same_user_org?
    @record.user.organisation_ids.intersect?(current_agent.organisation_ids)
  end
end
