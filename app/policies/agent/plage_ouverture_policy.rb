class Agent::PlageOuverturePolicy < ApplicationPolicy
  include CurrentAgentInPolicyConcern

  def update?
    can_manage_all_agent?
  end

  alias new? update?
  alias create? update?
  alias edit? update?
  alias destroy? update?

  alias show? update?
  alias versions? update?

  private

  def can_manage_all_agent?
    return true if @record.agents == [current_agent]

    agents_i_can_manage = Agent::AgentPolicy::Scope.apply(current_agent, Agent.all).merge(@record.organisation.agents).ids
    @record.agents.all? { |agent| agent.id.in?(agents_i_can_manage) }
  end

  def can_set_all_motifs?
    @record.motifs.all? { |motif| motif.organisation == @record.organisation }
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
          .joins(:agent_plages)
          .where(
            "agent_plages.agent_id = ?
              OR (agent_plages.agent_id IN (?) AND agent_roles.access_level = 'basic')
              OR (agent_roles.access_level = 'admin')",
            current_agent.id, confreres_of_my_orgs.ids
          )
      end
    end
  end
end
