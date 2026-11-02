class Agent::ParticipationPolicy < DefaultAgentPolicy
  def show?
    super || @record.created_by == current_agent
  end

  def update?
    Agent::RdvPolicy.new(@pundit_user, @record.rdv).update?
  end

  class Scope < Scope
    def resolve
      accessible_rdvs = Agent::RdvPolicy::Scope.new(context, Rdv.all).resolve
      scope.joins(:rdv).where(rdv: accessible_rdvs)
    end
  end
end
