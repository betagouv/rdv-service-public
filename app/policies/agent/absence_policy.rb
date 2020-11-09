class Agent::AbsencePolicy < DefaultAgentPolicy
  class Scope < Scope
    def resolve
      new_scope = scope.where(organisation_id: @context.agent.organisations.pluck(:id))
      new_scope = new_scope.where(organisation_id: @context.organisation.id) if @context.organisation.present?
      unless @context.agent.can_access_others_planning?
        new_scope = new_scope
          .joins(:agent)
          .where(agents: { service_id: @context.agent.service_id })
      end
      new_scope
    end
  end
end
