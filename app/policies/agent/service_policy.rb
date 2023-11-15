class Agent::ServicePolicy < Agent::AdminPolicy
  class Scope < Scope
    def resolve
      if current_agent_role.admin? || current_agent.secretaire?
        return scope.in_verticale(current_agent_role.organisation.verticale)
      end

      scope.where(id: current_agent.services.select(:id))
    end
  end

  class AdminScope < Scope
    def resolve
      # https://github.com/betagouv/rdv-solidarites.fr/pull/3868#pullrequestreview-1729410580
      return scope.where(id: Service.secretariat.id) if current_agent.conseiller_numerique?
      return scope.in_verticale(current_agent_role.organisation.verticale) if current_agent_role.admin?

      scope.where(id: current_agent.services.select(:id))
    end
  end
end
