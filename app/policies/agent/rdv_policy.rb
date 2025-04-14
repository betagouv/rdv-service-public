class Agent::RdvPolicy < ApplicationPolicy
  include CurrentAgentInPolicyConcern

  def create?
    users_and_agents_authorized? && motif_authorized?
  end
  alias new? create?

  def update?
    same_agent_or_has_access? && users_authorized?
  end
  alias status? update?

  def edit?
    same_agent_or_has_access? && users_authorized?
  end

  def show?
    # Nous n'examinons pas les usagers du RDV pour un show, car parfois des
    # usagers sont retirés de l'orga, mais on veut quand-même pouvoir afficher le RDV.
    same_agent_or_has_access?
  end
  alias versions? show?

  def destroy?
    current_agent.access_level_in(@record.organisation) == AgentRole::ACCESS_LEVEL_ADMIN
  end

  def self.explain(organisation, agent)
    explainations = if agent.admin_in_organisation?(organisation)
                      "En tant qu'administrateur de l'organisation, vous voyez les RDV de toute l'organisation #{organisation.name}."
                    elsif agent.secretaire?
                      "En tant que membre du service secrétariat, vous voyez les RDV de toute l'organisation #{organisation.name}."
                    else
                      "En tant qu'agent, vous voyez uniquement les RDV de vos services ayant lieu dans l'organisation #{organisation.name}."
                    end
    explainations += " Vous voyez également les RDV auxquels vous êtes associé"
    explainations
  end

  private

  def users_and_agents_authorized?
    users_authorized? && agents_authorized?
  end

  def same_service?
    @record.motif.service_id.in?(current_agent.service_ids)
  end

  def agents_authorized?
    return @agents_authorized if defined?(@agents_authorized)

    rdv_agent_ids = record.agents_rdvs.map(&:agent).reject(&:soft_deleted?).map(&:id)
    @agents_authorized = (authorized_agent_ids_via_scope(rdv_agent_ids) + authorized_agent_ids_via_motif(rdv_agent_ids)).to_set == rdv_agent_ids.to_set

    notify_agents_unauthorized unless @agents_authorized

    @agents_authorized
  end

  def authorized_agent_ids_via_scope(rdv_agent_ids)
    Agent::AgentPolicy::Scope.new(pundit_user, Agent).resolve
      .where(id: rdv_agent_ids).pluck(:id)
  end

  def authorized_agent_ids_via_motif(rdv_agent_ids)
    return [] if record.motif.blank?

    record.motif.authorized_agents.where(id: rdv_agent_ids).pluck(:id)
  end

  def users_authorized?
    return @users_authorized if defined?(@users_authorized)

    participants = record.participations.map(&:user).reject(&:soft_deleted?).map(&:id).to_set

    territory_scope_users = Agent::UserPolicy::TerritoryScope.new(agent_organisation_context, User).resolve
      .where(id: participants).pluck(:id).to_set

    participants_not_in_territory_scope = participants.difference(territory_scope_users)
    @users_authorized = if participants_not_in_territory_scope.empty?
                          # Tous les participants sont dans mon périmètre
                          true
                        else
                          # Temporaire : si un usager n'est pas dans mon périmètre (orga / territoire)
                          # mais qu'il participe à des RDV que je peux voir, c'est OK.
                          # Voir : https://github.com/betagouv/rdv-service-public/pull/5023
                          users_of_rdvs_i_can_see = Scope.new(current_agent, Rdv.joins(:participations).where(participations: { user_id: participants_not_in_territory_scope })).resolve
                          users_of_rdvs_i_can_see.pluck("participations.user_id").to_set == participants_not_in_territory_scope
                        end

    notify_users_unauthorized unless @users_authorized

    @users_authorized
  end

  def motif_authorized?
    record.motif.blank? ||
      Agent::MotifPolicy.agent_can_use_motif?(record.motif, current_agent)
  end

  def agent_organisation_context
    if pundit_user.respond_to?(:agent) && pundit_user.respond_to?(:organisation)
      pundit_user
    else
      AgentOrganisationContext.new(pundit_user, record.organisation)
    end
  end

  def notify_agents_unauthorized
    Sentry.capture_message(
      "L'agent n'est pas autorisé à créer de RDV avec ces agents",
      extra: { agent_ids: record.agent_ids, agent: current_agent.id }
    )
  end

  def notify_users_unauthorized
    Sentry.capture_message(
      "L'agent n'est pas autorisé à créer de RDV avec ces usagers : mettre à jour https://www.notion.so/rdvs/1832b05ced41805e82a9cb0e2567cfc9",
      extra: { user_ids: record.user_ids, agent: current_agent.id }
    )
  end

  def same_agent_or_has_access?
    return true if current_agent.participates_in?(@record)

    case current_agent.access_level_in(@record.organisation)
    when AgentRole::ACCESS_LEVEL_ADMIN
      true
    when AgentRole::ACCESS_LEVEL_BASIC
      same_service? || current_agent.secretaire?
    else
      false
    end
  end

  class Scope < Scope
    include CurrentAgentInPolicyConcern

    def resolve
      # NOTE: IMPORTANTE: Ce scope peut renvoyer des RDV doublons à cause des INNER JOIN vers les participations et les agents.
      if current_agent.secretaire?
        scope.joins("INNER JOIN agent_roles on agent_roles.organisation_id = rdvs.organisation_id")
          .where(agent_roles: { agent_id: current_agent.id }) # RDV des organisations dans lesquelles j'ai un role
      else
        scope.joins("INNER JOIN agent_roles on agent_roles.organisation_id = rdvs.organisation_id")
          .where(agent_roles: { agent_id: current_agent.id }) # RDV des organisations dans lesquelles j'ai un role
          .joins(:motif, :agents_rdvs)
          .where(
            "agents_rdvs.agent_id = ?
              OR (motifs.service_id IN (?) AND agent_roles.access_level = 'basic')
              OR (agent_roles.access_level = 'admin')",
            current_agent.id, current_agent.service_ids
          )
      end
    end
  end
end
