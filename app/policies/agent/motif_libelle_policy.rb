# frozen_string_literal: true

class Agent::MotifLibellePolicy < Agent::AdminPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end
end
