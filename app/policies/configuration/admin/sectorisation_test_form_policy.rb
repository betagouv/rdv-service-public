# frozen_string_literal: true

class Configuration::Admin::SectorisationTestFormPolicy
  class Scope
    def initialize(context, scope)
      @context = context
      @scope = scope
    end

    def resolve
      @scope
    end
  end
end
