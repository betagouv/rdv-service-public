class Agent::ParticipationPolicy < DefaultAgentPolicy
  def show?
    super || @record.created_by == current_agent
  end

  class Scope < Scope
    def resolve
      accessible_rdvs = Agent::RdvPolicy::Scope.new(context, Rdv.all).resolve
      scope.joins(:rdv).where(rdvs: accessible_rdvs)
    end
  end
end
