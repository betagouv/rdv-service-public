# frozen_string_literal: true

class TeamPolicy
  class Scope
    def initialize(territory, scope)
      @territory = territory
      @scope = scope
    end

    def resolve
      @scope.where(territory: @territory)
    end
  end
end
