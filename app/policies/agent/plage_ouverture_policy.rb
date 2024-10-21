class Agent::PlageOuverturePolicy < ApplicationPolicy
  include CurrentAgentInPolicyConcern

  def update?
    same_agent_or_has_access?
  end

  alias new? update?
  alias create? update?
  alias edit? update?
  alias destroy? update?

  alias show? update?
  alias versions? update?

  private

  def same_agent_or_has_access?
    return true if @record.agent == current_agent

    case current_agent.access_level_in(@record.organisation)
    when AgentRole::ACCESS_LEVEL_ADMIN
      true
    when AgentRole::ACCESS_LEVEL_BASIC
      same_service? || current_agent.secretaire?
    else
      false
    end
  end

  def same_service?
    @record.agent.confrere_of?(current_agent)
  end

  class Scope < Scope
    include CurrentAgentInPolicyConcern

    def resolve
      plages_of_my_orgs = scope.joins("INNER JOIN agent_roles ON agent_roles.organisation_id = plage_ouvertures.organisation_id")
        .where(agent_roles: { agent_id: current_agent.id }) # plages des organisations dans lesquelles j'ai un role

      if current_agent.secretaire?
        plages_of_my_orgs
      else
        confreres_of_my_orgs = current_agent.confreres.joins(:roles)
          .where(agent_roles: { organisation_id: current_agent.organisations })

        plages_of_my_orgs
          .where(
            "plage_ouvertures.agent_id = ?
              OR (plage_ouvertures.agent_id IN (?) AND agent_roles.access_level = 'basic')
              OR (agent_roles.access_level = 'admin')",
            current_agent.id, confreres_of_my_orgs.ids
          )
      end
    end
  end
end
