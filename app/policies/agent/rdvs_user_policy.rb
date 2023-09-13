# frozen_string_literal: true

class Agent::RdvsUserPolicy < DefaultAgentPolicy
  class Scope < Scope
    alias context pundit_user
    delegate :agent, to: :context, prefix: :current # defines current_agent

    def resolve
      scope.joins(:rdv).where(rdvs: { organisation: current_agent.organisations_of_territorial_roles })
    end
  end
end
