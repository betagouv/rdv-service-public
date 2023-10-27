class Agent::RdvsUserPolicy < DefaultAgentPolicy
  class Scope < Scope
    def resolve
      accessible_rdvs = Agent::RdvPolicy::Scope.new(context, Rdv.all).resolve
      scope.joins(:rdv).where(rdvs: accessible_rdvs)
    end
  end
end
