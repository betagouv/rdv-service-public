class Agent::RdvPolicy < DefaultAgentPolicy
  def status?
    same_agent_or_has_access?
  end

  class Scope < Scope
    def resolve
      if @context.can_access_others_planning?
        scope.where(organisation_id: @context.organisation.id)
      else
        scope.joins(:motif).where(organisation_id: @context.organisation.id, motifs: { service_id: @context.agent.service_id })
      end
    end
  end

  class DepartementScope < Scope
    def resolve
      if @context.can_access_others_planning?
        scope.where(organisation_id: @context.agent.organisations.pluck(:id))
      else
        scope.joins(:motif)
          .where(organisation_id: @context.agent.organisations.pluck(:id))
          .where(motifs: { service_id: @context.agent.service_id })
      end
    end
  end
end
